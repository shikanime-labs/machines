//! Stack graph resolution + lifecycle.
//!
//! Owns the linear active-stack model that `submit`/`land`/`close` share:
//! walk change-parent edges from `@`, skip commits whose head already has a
//! closed/merged PR, push each head, upsert a PR per live commit, append a
//! `---` separator to each PR body, and drive the three workflows.
//!
//! Centralizing this keeps PR resolution identical across workflows and gives
//! the stack a first-class `Stack`/`PrLink` abstraction instead of loose
//! `(head, pr_number, title, body)` tuples threaded through `jjplus`.

use crate::jjplus::Client;
use std::collections::HashSet;
use std::error::Error;

/// One PR in the resolved active stack, in root-first order.
#[derive(Debug)]
pub struct PrLink {
    /// Change id under test (e.g. `abc` / `@`).
    pub id: String,
    /// Resolved `push-<change>` bookmark for this commit.
    pub head: String,
    /// The PR number opened/updated for this head.
    pub pr_number: u64,
    /// PR title (first line of the commit description).
    pub title: String,
    /// PR body (rest of the commit description).
    pub body: String,
    /// True for dependent PRs (everything except the root); the root is
    /// based on trunk and is non-draft.
    pub is_draft: bool,
}

/// A resolved, root-first active stack ready for submit/land/close.
#[derive(Debug)]
pub struct Stack {
    /// Live PR links, root-first (closest to trunk first).
    pub links: Vec<PrLink>,
    /// Trunk bookmark name (base of the root PR).
    pub trunk: String,
}

impl Stack {
    /// Walk `@` down to trunk, skip done PRs, push heads, upsert PRs.
    ///
    /// Produces the root-first chain of live (open) PRs. A commit whose
    /// `push-*` head already has a closed/merged PR is popped so it can't be
    /// reopened or re-merged (ghstack errors on that). `submit`/`land`/`close`
    /// all funnel through this so resolution stays identical.
    pub fn resolve(client: &Client, remote: &str, trunk: &str) -> Result<Stack, Box<dyn Error>> {
        let ids = resolve_stack_ids(client)?;
        let mut links: Vec<PrLink> = Vec::new();
        // Previous non-skipped head; the first live commit bases on trunk.
        let mut prev_head: Option<String> = None;
        for id in &ids {
            let head = push_head_bookmark(client, id, remote)?;
            // Pop done commits: a closed/merged PR already landed and must
            // not be reopened/reedited.
            if client.gh.pr_is_done(&head)? {
                println!("skipped {id} -> {head} (PR already closed/merged)");
                continue;
            }
            let (title, body) = pr_metadata(client, id);
            let base = prev_head.clone().unwrap_or_else(|| trunk.to_string());
            let is_draft = prev_head.is_some();
            let pr_number = upsert_pr(client, &head, &title, &body, &base, is_draft)?;
            prev_head = Some(head.clone());
            links.push(PrLink {
                id: id.clone(),
                head,
                pr_number,
                title,
                body,
                is_draft,
            });
        }
        Ok(Stack {
            links,
            trunk: trunk.to_string(),
        })
    }

    /// Append a `---` separator to the current PR (`@`, last in the
    /// root-first chain) body only.
    pub fn sync_graph(&self, client: &Client) -> Result<(), Box<dyn Error>> {
        if let Some(link) = self.links.last() {
            let body = format!("{}\n\n---\n", link.body);
            client.gh.pr_edit(link.pr_number, &link.title, &body)?;
        }
        Ok(())
    }

    /// Un-draft the bottom (root) PR so the stack is reviewable/closeable.
    pub fn ensure_bottom_open(&self, client: &Client) -> Result<(), Box<dyn Error>> {
        if let Some(link) = self.links.first() {
            client.gh.pr_ready(link.pr_number)?;
        }
        Ok(())
    }

    /// Merge root-first so each dependent lands on top of its base.
    pub fn merge_all(&self, client: &Client) -> Result<(), Box<dyn Error>> {
        for link in &self.links {
            client.gh.pr_ready(link.pr_number)?;
            client.gh.pr_merge(link.pr_number)?;
            println!("landed {} -> PR #{}", link.id, link.pr_number);
        }
        Ok(())
    }

    /// Close dependents-first so the root (nearest trunk) closes last.
    pub fn close_all(&self, client: &Client) -> Result<(), Box<dyn Error>> {
        self.ensure_bottom_open(client)?;
        for link in self.links.iter().rev() {
            client.gh.pr_close(link.pr_number)?;
            println!("closed {} -> PR #{}", link.id, link.pr_number);
        }
        Ok(())
    }

    /// submit = sync graph + ensure bottom open (never merges).
    pub fn submit(&self, client: &Client) -> Result<(), Box<dyn Error>> {
        self.sync_graph(client)?;
        self.ensure_bottom_open(client)?;
        Ok(())
    }

    /// Resolve + submit; report when nothing is open.
    pub fn resolve_and_submit(client: &Client, remote: &str) -> Result<(), Box<dyn Error>> {
        let trunk = client.resolve_trunk()?;
        let stack = Stack::resolve(client, remote, &trunk)?;
        if stack.links.is_empty() {
            println!("jjplus: nothing to submit (no open PRs in the stack)");
            return Ok(());
        }
        stack.submit(client)
    }

    /// Resolve + land (merge root-first); report when the stack is empty.
    pub fn resolve_and_land(client: &Client, remote: &str) -> Result<(), Box<dyn Error>> {
        let trunk = client.resolve_trunk()?;
        let stack = Stack::resolve(client, remote, &trunk)?;
        if stack.links.is_empty() {
            println!("jjplus: nothing to land (stack is empty)");
            return Ok(());
        }
        stack.merge_all(client)
    }

    /// Resolve + close (dependents-first); report when the stack is empty.
    pub fn resolve_and_close(client: &Client, remote: &str) -> Result<(), Box<dyn Error>> {
        let trunk = client.resolve_trunk()?;
        let stack = Stack::resolve(client, remote, &trunk)?;
        if stack.links.is_empty() {
            println!("jjplus: nothing to close (stack is empty)");
            return Ok(());
        }
        stack.close_all(client)
    }
}

/// Resolve the stack to submit, root-first (closest to trunk first).
///
/// Walks change-parent edges from `@` so the order is stable regardless of
/// which tail `submit` runs from. Single DAG => one linear chain; multi-root
/// / multi-tail DAGs are not handled (ponytail: DFS, O(commits) jj calls).
fn resolve_stack_ids(client: &Client) -> Result<Vec<String>, Box<dyn Error>> {
    let mut order: Vec<String> = Vec::new();
    let mut seen: HashSet<String> = HashSet::new();
    walk_parents(client, "@", &mut seen, &mut order)?;
    Ok(order)
}

/// Recursively collect `id` then its change-parents, root-first.
fn walk_parents(
    client: &Client,
    id: &str,
    seen: &mut HashSet<String>,
    out: &mut Vec<String>,
) -> Result<(), Box<dyn Error>> {
    if !seen.insert(id.to_string()) {
        return Ok(()); // cycle guard / already emitted
    }
    let parents = client
        .jj
        .log(id, "parents.map(|c| c.change_id().short()).join(\",\")")?
        .split(',')
        .map(str::trim)
        .filter(|p| !p.is_empty())
        .map(str::to_string)
        .collect::<Vec<_>>();
    // Emit parents first, then self — bottom-up ordering.
    for p in &parents {
        walk_parents(client, p, seen, out)?;
    }
    out.push(id.to_string());
    Ok(())
}

/// Push `id` and return its `push-<change>` bookmark name.
fn push_head_bookmark(client: &Client, id: &str, remote: &str) -> Result<String, Box<dyn Error>> {
    client.jj.git_push(id, remote)?;
    let prefix = client.jj.push_bookmark_prefix()?;
    let out = client.jj.log(id, "bookmarks.join(\",\")")?;
    out.split(',')
        .map(str::trim)
        .find(|b| b.starts_with(&prefix) && b.len() > prefix.len())
        .map(str::to_string)
        .ok_or_else(|| format!("no push bookmark for {id} (did `jj git push` run?)").into())
}

/// Title (first line) + body (rest) for the PR opened from a commit.
fn pr_metadata(client: &Client, id: &str) -> (String, String) {
    let raw = client.jj.log(id, "description").unwrap_or_default();
    match raw.split_once('\n') {
        Some((t, b)) => (t.trim().to_string(), b.to_string()),
        None => (raw.trim().to_string(), String::new()),
    }
}

/// Edit the existing PR for `head`, or create a new one; return its number.
fn upsert_pr(
    client: &Client,
    head: &str,
    title: &str,
    body: &str,
    base: &str,
    is_draft: bool,
) -> Result<u64, Box<dyn Error>> {
    if let Ok(prs) = client.gh.pr_list(head) {
        if let Some(pr) = prs.into_iter().next() {
            client.gh.pr_edit(pr.number, title, body)?;
            if is_draft {
                let repo = client.gh.repo_view()?;
                client.gh.api_patch_draft(&repo, pr.number)?;
            }
            return Ok(pr.number);
        }
    }
    Ok(client.gh.pr_create_num(title, body, head, base, is_draft)?)
}
