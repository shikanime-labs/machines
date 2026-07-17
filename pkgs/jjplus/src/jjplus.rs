//! `jjplus` facade: bundles `jj` + `gh` into the `switch`/`checkout`/`remove`/`submit`/`land`/`close` workflows.
use crate::github;
use crate::jj;
use crate::runner::{Runner, RunnerError};
use std::env;
use std::error::Error;
use std::fmt::Write;
use std::fs;
use std::path::PathBuf;

/// The `jjplus` facade: bundles `jj` + `gh` behind one runner and exposes the
/// high-level workflows (`switch`, `checkout`, `remove`, `submit`, `land`, `close`).
pub struct Client<'a> {
    pub jj: jj::Client<'a>,
    pub gh: github::Client<'a>,
}

impl<'a> Client<'a> {
    /// Bundle a `jj` and `gh` client over the same runner.
    pub fn new(runner: &'a dyn Runner) -> Self {
        Client {
            jj: jj::Client::new(runner),
            gh: github::Client::new(runner),
        }
    }
}

/// `<name>` -> `<name>.xxx` (ponytail: fixed `.xxx` convention, no --path).
fn workspace_path(name: &str) -> PathBuf {
    let mut p = PathBuf::from(name);
    p.set_extension("xxx");
    p
}

/// Render the ghstack `Stack from [...]` block for the whole chain.
///
/// `chain` is root-first: each entry is
/// `(push-<id>, pr_number, title, body)`. ghstack lists PRs root-first too.
fn stack_graph(chain: &[(String, u64, String, String)]) -> String {
    let mut g = String::from(
        "\n\nStack from [jjplus](https://github.com/shikanime-labs/machines) (oldest at bottom):\n",
    );
    for (_, num, _, _) in chain {
        let _ = writeln!(g, "* __->__ #{num}");
    }
    g
}

impl<'a> Client<'a> {
    /// Create a workspace named `<name>.xxx` (optionally checked out at `rev`).
    /// Prints its absolute path unless `--no-move`.
    pub fn switch(
        &self,
        name: &str,
        no_move: bool,
        rev: Option<&str>,
    ) -> Result<(), Box<dyn Error>> {
        let dest = workspace_path(name);
        let dest_str = dest.to_str().ok_or("destination path is not valid UTF-8")?;
        self.jj.workspace_add(dest_str, rev)?;
        if !no_move {
            let abs = env::current_dir()?.join(&dest);
            println!("{}", abs.display());
        }
        Ok(())
    }

    /// Checkout a PR (by URL) into a workspace named by its head ref.
    pub fn checkout(&self, url: &str, no_move: bool) -> Result<(), Box<dyn Error>> {
        let head = self.gh.pr_view_head(url)?;
        if head.is_empty() {
            return Err(format!("could not resolve head ref from PR `{url}`").into());
        }
        self.jj.git_fetch()?;
        self.switch(&head, no_move, Some(&head))
    }

    /// Forget and delete a workspace created by `switch`/`checkout`.
    pub fn remove(&self, name: &str) -> Result<(), Box<dyn Error>> {
        let dest = workspace_path(name);
        let dest_str = dest.to_str().ok_or("workspace path is not valid UTF-8")?;
        // Forget first; never `rm -rf` a live/unknown workspace.
        self.jj.workspace_forget(dest_str)?;
        if dest.exists() {
            fs::remove_dir_all(&dest)?;
        }
        println!("removed workspace at {}", dest.display());
        Ok(())
    }

    /// Resolve the stack to submit, root-first (closest to trunk first).
    fn resolve_stack_ids(&self) -> Result<Vec<String>, Box<dyn Error>> {
        let mut ids = self
            .jj
            .log("(trunk()..@) ~ @", "change_id.short() ++ \"\n\"")?
            .lines()
            .map(str::trim)
            .filter(|l| !l.is_empty())
            .map(str::to_string)
            .collect::<Vec<_>>();
        // Revset yields leaf-first; reverse so dependents stack on the previous PR.
        ids.reverse();
        Ok(ids)
    }

    /// Resolve the trunk bookmark name (base of the stack).
    fn resolve_trunk(&self) -> Result<String, Box<dyn Error>> {
        let trunk = self
            .jj
            .log("trunk()", "bookmarks.first()")?
            .trim()
            .to_string();
        if trunk.is_empty() {
            return Err("could not resolve trunk() bookmark".into());
        }
        Ok(trunk)
    }

    /// Push `id` to `remote` and return its push bookmark name
    /// (prefix resolved from `templates.git_push_bookmark`).
    fn push_head_bookmark(&self, id: &str, remote: &str) -> Result<String, RunnerError> {
        self.jj.git_push(id, remote).map_err(|e| e.to_string())?;
        let prefix = self.jj.push_bookmark_prefix().map_err(|e| e.to_string())?;
        let out = self
            .jj
            .log(id, "bookmarks.join(\",\")")
            .map_err(|e| e.to_string())?;
        out.split(',')
            .map(str::trim)
            .find(|b| b.starts_with(&prefix) && b.len() > prefix.len())
            .map(str::to_string)
            .ok_or_else(|| format!("no push bookmark for {id} (did `jj git push` run?)"))
    }

    /// Title and body for the PR opened from a commit.
    fn pr_metadata(&self, id: &str) -> (String, String) {
        let raw = self.jj.log(id, "description").unwrap_or_default();
        // first line is the title; body is everything after it.
        let (title, body) = match raw.split_once('\n') {
            Some((t, b)) => (t.trim().to_string(), b.to_string()),
            None => (raw.trim().to_string(), String::new()),
        };
        (title, body)
    }

    /// Edit the existing PR for `head`, or create a new one; return its number.
    fn upsert_pr(
        &self,
        head: &str,
        title: &str,
        body: &str,
        base: &str,
        is_draft: bool,
    ) -> Result<u64, Box<dyn Error>> {
        let existing = self.gh.pr_list(head)?;
        if let Some(pr) = existing.into_iter().next() {
            self.gh.pr_edit(pr.number, title, body)?;
            if is_draft {
                let repo = self.gh.repo_view()?;
                self.gh.api_patch_draft(&repo, pr.number)?;
            }
            Ok(pr.number)
        } else {
            Ok(self.gh.pr_create_num(title, body, head, base, is_draft)?)
        }
    }

    /// Push the whole stack and open/update a GitHub PR per commit (ghstack-style),
    /// skipping any commit whose `push-*` head already has a closed/merged PR.
    ///
    /// ghstack errors if you reopen or re-edit an already-landed PR, so those
    /// "done" commits are popped from the active stack here. `submit` only
    /// *opens* PRs; it never merges. Use `land` to merge or `close` to close.
    pub fn submit(&self, remote: &str) -> Result<(), Box<dyn Error>> {
        let ids = self.resolve_stack_ids()?;
        if ids.is_empty() {
            println!("jjplus: nothing to submit (stack is empty)");
            return Ok(());
        }
        let trunk = self.resolve_trunk()?;
        eprintln!("DBG ids={ids:?} trunk={trunk}");

        let mut heads: Vec<String> = Vec::new();
        // (push-<id>, pr_number, title, body) per commit, root-first.
        // ponytail: linear stack; a DAG would need a 2D ancestor map.
        let mut chain: Vec<(String, u64, String, String)> = Vec::new();
        // Previous non-skipped head; the first live commit bases on trunk.
        // ponytail: a skipped (done) commit must NOT become a base.
        let mut prev_head: Option<String> = None;
        for (i, id) in ids.iter().enumerate() {
            let head = self.push_head_bookmark(id, remote)?;
            // Pop done commits: a closed/merged PR for this head means it already
            // landed and should not be reopened/re-edited.
            if self.gh.pr_is_done(&head)? {
                eprintln!("DBG is_done {head}=true -> skip");
                continue;
            }
            heads.push(head.clone());
            let (title, body) = self.pr_metadata(id);
            // Base is trunk for the first live commit, else the previous
            // live head (skipped commits are excluded via `prev_head`).
            let base = match &prev_head {
                Some(h) => h.clone(),
                None => trunk.clone(),
            };
            let is_draft = prev_head.is_some();
            let pr_num = self.upsert_pr(&head, &title, &body, &base, is_draft)?;
            prev_head = Some(head.clone());
            chain.push((head.clone(), pr_num, title.clone(), body.clone()));

            let _ = i;
            println!(
                "{} -> {} ({}{})",
                id,
                head,
                if prev_head.is_none() {
                    "root, base=".to_string() + &trunk
                } else {
                    "depends on ".to_string() + prev_head.as_ref().unwrap()
                },
                if is_draft { ", draft" } else { "" }
            );
            println!("   PR: #{pr_num}");
        }

        // Re-write every PR body to embed the full stack graph (ghstack
        // style: each PR shows the whole chain). Two passes because the
        // PR numbers aren't known until the create/edit pass above.
        // ponytail: O(n) extra edits, fine for linear stacks.
        let graph = stack_graph(&chain);
        for (_, num, title, body) in &chain {
            let body = format!("{body}{graph}");
            self.gh.pr_edit(*num, title, &body)?;
        }

        // Defensive: the bottom PR (nearest `main`, chain[0]) must always be
        // open and non-draft so the stack is reviewable/mergeable from the base.
        if let Some((_, num, _, _)) = chain.first() {
            self.gh.pr_ready(*num)?;
        }
        Ok(())
    }

    /// Merge the current stack's PRs in graph order (root-first), popping any
    /// commit whose `push-*` head already has a closed/merged PR.
    ///
    /// `resolve_stack_ids` already yields root-first; merging the root first
    /// lets each dependent (based on the previous PR's head) land on top.
    /// An already-landed PR is skipped rather than re-merged.
    pub fn land(&self, remote: &str) -> Result<(), Box<dyn Error>> {
        let ids = self.resolve_stack_ids()?;
        if ids.is_empty() {
            println!("jjplus: nothing to land (stack is empty)");
            return Ok(());
        }
        for id in &ids {
            let head = self.push_head_bookmark(id, remote)?;
            // Pop done commits: nothing to do if the PR already merged/closed.
            if self.gh.pr_is_done(&head)? {
                println!("skipped {id} -> {head} (PR already closed/merged)");
                continue;
            }
            let pr =
                self.gh.pr_list(&head)?.into_iter().next().ok_or_else(|| {
                    format!("no PR found for head `{head}` (did you run submit?)")
                })?;
            self.gh.pr_ready(pr.number)?;
            self.gh.pr_merge(pr.number)?;
            println!("landed {} -> PR #{}", id, pr.number);
        }
        Ok(())
    }

    /// Close the whole stack's PRs, nearest `main` last (root-first).
    ///
    /// ghstack-style close: the bottom (root) PR is marked ready first, then
    /// every PR — including the root — is closed in graph order so the PR
    /// closest to `main` is closed last. Already-closed/merged PRs are
    /// popped (nothing to do). Does not merge; use [`Client::land`] for that.
    pub fn close(&self, remote: &str) -> Result<(), Box<dyn Error>> {
        let ids = self.resolve_stack_ids()?;
        if ids.is_empty() {
            println!("jjplus: nothing to close (stack is empty)");
            return Ok(());
        }
        let mut bottom: Option<u64> = None;
        let mut closable: Vec<u64> = Vec::new();
        for id in &ids {
            let head = self.push_head_bookmark(id, remote)?;
            // Pop done PRs; nothing to close if it already merged/closed.
            if self.gh.pr_is_done(&head)? {
                println!("skipped {id} -> {head} (PR already closed/merged)");
                continue;
            }
            let pr =
                self.gh.pr_list(&head)?.into_iter().next().ok_or_else(|| {
                    format!("no PR found for head `{head}` (did you run submit?)")
                })?;
            if bottom.is_none() {
                bottom = Some(pr.number);
            }
            closable.push(pr.number);
        }
        // Un-draft the bottom PR so it can be closed cleanly.
        if let Some(n) = bottom {
            self.gh.pr_ready(n)?;
        }
        // Close in graph order (root-first): nearest `main` is last.
        for n in closable {
            self.gh.pr_close(n)?;
            println!("closed PR #{n}");
        }
        Ok(())
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    use crate::runner::RunnerError;
    use std::cell::RefCell;
    use std::rc::Rc;

    /// Runner that records every call and answers via a canned responder.
    struct RecordingRunner {
        calls: Rc<RefCell<Vec<(String, Vec<String>)>>>,
        responder: Box<dyn Fn(&str, &[&str]) -> Result<String, RunnerError>>,
    }
    impl Runner for RecordingRunner {
        fn run(&self, program: &str, args: &[&str]) -> Result<String, RunnerError> {
            self.calls.borrow_mut().push((
                program.to_string(),
                args.iter().map(|s| s.to_string()).collect(),
            ));
            (self.responder)(program, args)
        }
    }

    /// Calls whose program matches and whose args contain every substring in `must`.
    fn find_calls(
        calls: &[(String, Vec<String>)],
        program: &str,
        must: &[&str],
    ) -> Vec<(String, Vec<String>)> {
        calls
            .iter()
            .filter(|(p, a)| p == program && must.iter().all(|m| a.iter().any(|x| x.contains(m))))
            .cloned()
            .collect()
    }

    fn has(calls: &[(String, Vec<String>)], program: &str, must: &[&str]) -> bool {
        !find_calls(calls, program, must).is_empty()
    }

    /// `gh pr merge` calls carry `--squash`; `gh pr list --state merged`
    /// also contains "merge", so filter on the merge flag to isolate real merges.
    fn merges(calls: &[(String, Vec<String>)]) -> Vec<(String, Vec<String>)> {
        find_calls(calls, "gh", &["pr", "merge", "--squash"])
    }

    #[test]
    fn workspace_path_appends_xxx() {
        assert_eq!(workspace_path("foo"), PathBuf::from("foo.xxx"));
        assert_eq!(
            workspace_path("feature/login"),
            PathBuf::from("feature/login.xxx")
        );
    }

    #[test]
    fn switch_by_rev_calls_workspace_add_with_rev() {
        let calls: Rc<RefCell<Vec<(String, Vec<String>)>>> = Rc::new(RefCell::new(Vec::new()));
        let r = RecordingRunner {
            calls: calls.clone(),
            responder: Box::new(|_, _| Ok(String::new())),
        };
        let c = Client::new(&r);
        c.switch("abc", true, Some("abc")).unwrap();
        let cl = calls.borrow().clone();
        assert!(has(
            &cl,
            "jj",
            &["workspace", "add", "-r", "abc", "abc.xxx"]
        ));
    }

    #[test]
    fn switch_by_rev_uses_name_when_given() {
        let calls: Rc<RefCell<Vec<(String, Vec<String>)>>> = Rc::new(RefCell::new(Vec::new()));
        let r = RecordingRunner {
            calls: calls.clone(),
            responder: Box::new(|_, _| Ok(String::new())),
        };
        let c = Client::new(&r);
        // `name` preceeds `-r`: workspace named "feature" (not the change id),
        // checked out at the resolved change id.
        c.switch("feature", true, Some("abc")).unwrap();
        let cl = calls.borrow().clone();
        assert!(has(
            &cl,
            "jj",
            &["workspace", "add", "-r", "abc", "feature.xxx"]
        ));
    }

    #[test]
    fn switch_by_rev_without_name_uses_change_id() {
        let calls: Rc<RefCell<Vec<(String, Vec<String>)>>> = Rc::new(RefCell::new(Vec::new()));
        let r = RecordingRunner {
            calls: calls.clone(),
            responder: Box::new(|_, _| Ok(String::new())),
        };
        let c = Client::new(&r);
        c.switch("abc", true, Some("abc")).unwrap();
        let cl = calls.borrow().clone();
        assert!(has(
            &cl,
            "jj",
            &["workspace", "add", "-r", "abc", "abc.xxx"]
        ));
    }

    #[test]
    fn switch_by_name_omits_rev() {
        let calls: Rc<RefCell<Vec<(String, Vec<String>)>>> = Rc::new(RefCell::new(Vec::new()));
        let r = RecordingRunner {
            calls: calls.clone(),
            responder: Box::new(|_, _| Ok(String::new())),
        };
        let c = Client::new(&r);
        c.switch("feature", true, None).unwrap();
        let cl = calls.borrow().clone();
        let add = find_calls(&cl, "jj", &["workspace", "add"]);
        assert_eq!(add.len(), 1);
        assert_eq!(add[0].1, vec!["workspace", "add", "feature.xxx"]);
    }

    #[test]
    fn checkout_runs_view_then_fetch_then_switch() {
        let calls: Rc<RefCell<Vec<(String, Vec<String>)>>> = Rc::new(RefCell::new(Vec::new()));
        let r = RecordingRunner {
            calls: calls.clone(),
            responder: Box::new(|program, args| {
                let has = |s: &str| args.iter().any(|a| a.contains(s));
                match (program, has("view"), has("fetch")) {
                    ("gh", true, _) => Ok("patch-1".into()),
                    ("jj", _, true) => Ok(String::new()),
                    _ => Ok(String::new()),
                }
            }),
        };
        let c = Client::new(&r);
        c.checkout("https://github.com/o/r/pull/1", true).unwrap();
        let cl = calls.borrow().clone();

        let i_view = cl
            .iter()
            .position(|(p, a)| p == "gh" && a.iter().any(|x| x.contains("view")))
            .unwrap();
        let i_fetch = cl
            .iter()
            .position(|(p, a)| p == "jj" && a.iter().any(|x| x.contains("fetch")))
            .unwrap();
        let i_add = cl
            .iter()
            .position(|(p, a)| {
                p == "jj"
                    && a.iter().any(|x| x.contains("workspace"))
                    && a.iter().any(|x| x.contains("add"))
            })
            .unwrap();

        assert!(i_view < i_fetch);
        assert!(i_fetch < i_add);
        assert!(has(
            &cl,
            "jj",
            &["workspace", "add", "-r", "patch-1", "patch-1.xxx"]
        ));
    }

    #[test]
    fn remove_forgets_workspace() {
        let calls: Rc<RefCell<Vec<(String, Vec<String>)>>> = Rc::new(RefCell::new(Vec::new()));
        let r = RecordingRunner {
            calls: calls.clone(),
            responder: Box::new(|_, _| Ok(String::new())),
        };
        let c = Client::new(&r);
        c.remove("foo").unwrap();
        let cl = calls.borrow().clone();
        assert!(has(&cl, "jj", &["workspace", "forget", "foo.xxx"]));
    }

    /// Responder for submit tests: single commit "abc" -> push-abc, trunk "main",
    /// title "Title", body "Body" (description is "Title\nBody").
    fn submit_responder() -> Box<dyn Fn(&str, &[&str]) -> Result<String, RunnerError>> {
        Box::new(|program, args| {
            let has = |s: &str| args.iter().any(|a| a.contains(s));
            match (
                program,
                has("change_id.short"),
                has("bookmarks.first"),
                has("bookmarks.join"),
            ) {
                ("jj", true, _, _) => Ok("abc\n".into()),
                ("jj", _, true, _) => Ok("main".into()),
                ("jj", _, _, true) => Ok("push-abc".into()),
                _ => match (
                    program,
                    has("git"),
                    has("push"),
                    has("description.first_line"),
                    has("description"),
                    has("list"),
                    has("create"),
                    has("edit"),
                    has("merged"),
                    has("closed"),
                    has("state"),
                ) {
                    ("jj", _, _, true, _, _, _, _, _, _, _) => Ok("Title".into()),
                    ("jj", _, _, _, true, _, _, _, _, _, _) => Ok("Title\nBody".into()),
                    ("jj", _, true, _, _, _, _, _, _, _, _) => Ok(String::new()),
                    // open pr_list (no --state) -> no PR yet.
                    ("gh", _, _, _, _, true, _, _, _, _, _) if !has("state") => Ok("[]".into()),
                    // pr_is_done (--state merged|closed): open -> [].
                    ("gh", _, _, _, _, _, _, true, _, _, _) => Ok("[]".into()),
                    ("gh", _, _, _, _, _, _, _, true, _, _) => Ok("[]".into()),
                    // pr_create_num parses the PR number from the created URL.
                    ("gh", _, _, _, _, _, true, _, _, _, _) => {
                        Ok("https://github.com/o/r/pull/42".into())
                    }
                    _ => Ok(String::new()),
                },
            }
        })
    }

    #[test]
    fn submit_single_commit_creates_root_pr_against_trunk() {
        let calls: Rc<RefCell<Vec<(String, Vec<String>)>>> = Rc::new(RefCell::new(Vec::new()));
        let r = RecordingRunner {
            calls: calls.clone(),
            responder: submit_responder(),
        };
        let c = Client::new(&r);
        c.submit("origin").unwrap();
        let cl = calls.borrow().clone();

        let pushes = find_calls(&cl, "jj", &["git", "push", "-c"]);
        assert_eq!(pushes.len(), 1, "exactly one commit -> one push");

        // pr_create_num carries -H (head) / -B (base) / --draft.
        let creates = find_calls(&cl, "gh", &["pr", "create"]);
        assert_eq!(creates.len(), 1, "no existing PR -> one create");
        let create = &creates[0].1;
        assert!(create.contains(&"push-abc".to_string()), "head = push-abc");
        assert!(create.contains(&"main".to_string()), "base = trunk (main)");
        assert!(
            !create.iter().any(|a| a == "--draft"),
            "root PR is not a draft"
        );

        // Second pass rewrites the body with the stack graph via pr edit.
        let edits = find_calls(&cl, "gh", &["pr", "edit"]);
        assert_eq!(edits.len(), 1, "one PR -> one graph rewrite");
        let edit = &edits[0].1;
        let title = &edit[edit.iter().position(|a| a == "--title").unwrap() + 1];
        let body = &edit[edit.iter().position(|a| a == "--body").unwrap() + 1];
        assert_eq!(title, "Title", "first line of commit -> PR title");
        assert!(body.contains("Body"), "rest of description -> PR body");
        assert!(body.contains("Stack from [jjplus]"), "graph appended");
    }

    /// Responder for a two-commit stack: "abc","def" -> push-abc/push-def.
    fn submit_two_responder() -> Box<dyn Fn(&str, &[&str]) -> Result<String, RunnerError>> {
        Box::new(|program, args| {
            let has = |s: &str| args.iter().any(|a| a.contains(s));
            match (
                program,
                has("change_id.short"),
                has("bookmarks.first"),
                has("bookmarks.join"),
            ) {
                ("jj", true, _, _) => Ok("abc\ndef\n".into()),
                ("jj", _, true, _) => Ok("main".into()),
                ("jj", _, _, true) => Ok(if args[2] == "abc" {
                    "push-abc"
                } else {
                    "push-def"
                }
                .into()),
                _ => match (
                    program,
                    has("git"),
                    has("push"),
                    has("description.first_line"),
                    has("description"),
                    has("list"),
                    has("create"),
                    has("edit"),
                    has("merged"),
                    has("closed"),
                    has("state"),
                ) {
                    ("jj", _, _, true, _, _, _, _, _, _, _) => Ok("Title".into()),
                    ("jj", _, _, _, true, _, _, _, _, _, _) => Ok("Title\nBody".into()),
                    ("jj", _, true, _, _, _, _, _, _, _, _) => Ok(String::new()),
                    // open pr_list (no --state) -> no PR yet.
                    ("gh", _, _, _, _, true, _, _, _, _, _) if !has("state") => Ok("[]".into()),
                    ("gh", _, _, _, _, _, _, true, _, _, _) => Ok("[]".into()),
                    ("gh", _, _, _, _, _, _, _, true, _, _) => Ok("[]".into()),
                    // pr_create_num returns #7 for either head; both are open here.
                    ("gh", _, _, _, _, _, true, _, _, _, _) => {
                        Ok("https://github.com/o/r/pull/7".into())
                    }
                    _ => Ok(String::new()),
                },
            }
        })
    }

    #[test]
    fn submit_two_commit_stack_chains_bases_and_drafts_deps() {
        let calls: Rc<RefCell<Vec<(String, Vec<String>)>>> = Rc::new(RefCell::new(Vec::new()));
        let r = RecordingRunner {
            calls: calls.clone(),
            responder: submit_two_responder(),
        };
        let c = Client::new(&r);
        c.submit("origin").unwrap();
        let cl = calls.borrow().clone();

        let pushes = find_calls(&cl, "jj", &["git", "push", "-c"]);
        assert_eq!(pushes.len(), 2, "two commits -> two pushes");

        // Final pass rewrites each PR body with the stack graph.
        let edits = find_calls(&cl, "gh", &["pr", "edit"]);
        assert_eq!(edits.len(), 2, "two PRs -> two graph rewrites");

        // The graph bullet is present in every rewritten body.
        assert!(
            edits
                .iter()
                .all(|e| e.1.iter().any(|x| x.contains("* __->__ #7")))
        );

        // Root (push-def, not draft) and dep (push-abc, draft) distinguished
        // via the `pr create` -H head + --draft flag.
        let creates = find_calls(&cl, "gh", &["pr", "create"]);
        let root = creates
            .iter()
            .find(|c| c.1.contains(&"push-def".to_string()))
            .unwrap();
        assert!(root.1.contains(&"main".to_string()), "root base = trunk");
        assert!(!root.1.iter().any(|a| a == "--draft"), "root not a draft");
        let dep = creates
            .iter()
            .find(|c| c.1.contains(&"push-abc".to_string()))
            .unwrap();
        assert!(dep.1.iter().any(|a| a == "--draft"), "dep is a draft");
    }

    #[test]
    fn submit_empty_stack_pushes_nothing() {
        let calls: Rc<RefCell<Vec<(String, Vec<String>)>>> = Rc::new(RefCell::new(Vec::new()));
        let r = RecordingRunner {
            calls: calls.clone(),
            responder: Box::new(|program, args| {
                let has = |s: &str| args.iter().any(|a| a.contains(s));
                if program == "jj" && has("change_id.short") {
                    Ok(String::new())
                } else {
                    Ok(String::new())
                }
            }),
        };
        let c = Client::new(&r);
        c.submit("origin").unwrap();
        let cl = calls.borrow().clone();
        assert!(find_calls(&cl, "jj", &["git", "push"]).is_empty());
        assert!(find_calls(&cl, "gh", &["pr"]).is_empty());
    }

    #[test]
    fn submit_formats_pr_description_with_dependency_graph() {
        let calls: Rc<RefCell<Vec<(String, Vec<String>)>>> = Rc::new(RefCell::new(Vec::new()));
        let r = RecordingRunner {
            calls: calls.clone(),
            responder: submit_responder(),
        };
        let c = Client::new(&r);
        c.submit("origin").unwrap();
        let cl = calls.borrow().clone();

        // The ghstack graph is written via `pr edit` (second pass).
        let edit = &find_calls(&cl, "gh", &["pr", "edit"])[0].1;
        let title = &edit[edit.iter().position(|a| a == "--title").unwrap() + 1];
        let body = &edit[edit.iter().position(|a| a == "--body").unwrap() + 1];

        assert_eq!(title, "Title", "first line of commit -> PR title");
        assert!(body.contains("Body"), "full commit description -> PR body");
        assert!(
            body.contains("Stack from [jjplus]"),
            "ghstack Stack from header is appended"
        );
        assert!(
            body.contains("* __->__ #42"),
            "ghstack bullet lists the PR number"
        );
        assert!(
            body.ends_with("* __->__ #42\n"),
            "graph is appended at the end of the body"
        );
    }

    /// Responder for a stack where push-def already has a merged PR (#8)
    /// and push-abc is open. `pr_is_done` is driven by `--state merged`.
    fn submit_with_done_responder() -> Box<dyn Fn(&str, &[&str]) -> Result<String, RunnerError>> {
        Box::new(|program, args| {
            let has = |s: &str| args.iter().any(|a| a.contains(s));
            match (
                program,
                has("change_id.short"),
                has("bookmarks.first"),
                has("bookmarks.join"),
            ) {
                ("jj", true, _, _) => Ok("abc\ndef\n".into()),
                ("jj", _, true, _) => Ok("main".into()),
                ("jj", _, _, true) => Ok(if args[2] == "abc" {
                    "push-abc"
                } else {
                    "push-def"
                }
                .into()),
                _ => match (
                    program,
                    has("git"),
                    has("push"),
                    has("description.first_line"),
                    has("description"),
                    has("list"),
                    has("create"),
                    has("edit"),
                    has("merged"),
                    has("closed"),
                    has("state"),
                ) {
                    ("jj", _, _, true, _, _, _, _, _, _, _) => Ok("Title".into()),
                    ("jj", _, _, _, true, _, _, _, _, _, _) => Ok("Title\nBody".into()),
                    ("jj", _, true, _, _, _, _, _, _, _, _) => Ok(String::new()),
                    // open pr_list (no --state) -> no PR yet.
                    ("gh", _, _, _, _, true, _, _, _, _, _) if !has("state") => Ok("[]".into()),
                    // pr_is_done --state merged: push-def done (#8); push-abc open.
                    ("gh", _, _, _, _, _, _, true, _, _, _) if has("push-def") => {
                        Ok("[{\"number\":8}]".into())
                    }
                    ("gh", _, _, _, _, _, _, true, _, _, _) => Ok("[]".into()),
                    ("gh", _, _, _, _, _, _, _, true, _, _) => Ok("[]".into()),
                    // pr_create_num: only the open head (push-abc) reaches here -> #7.
                    ("gh", _, _, _, _, _, true, _, _, _, _) => {
                        Ok("https://github.com/o/r/pull/7".into())
                    }
                    _ => Ok(String::new()),
                },
            }
        })
    }

    #[test]
    fn submit_skips_commits_with_closed_or_merged_prs() {
        let calls: Rc<RefCell<Vec<(String, Vec<String>)>>> = Rc::new(RefCell::new(Vec::new()));
        let r = RecordingRunner {
            calls: calls.clone(),
            responder: submit_with_done_responder(),
        };
        let c = Client::new(&r);
        c.submit("origin").unwrap();
        let cl = calls.borrow().clone();

        // Both branches are still pushed (to keep them fresh); the done one
        // is simply not reopened/reedited.
        let pushes = find_calls(&cl, "jj", &["git", "push", "-c"]);
        assert_eq!(pushes.len(), 2, "both commits are pushed");

        // Only the open PR (push-abc) is created; the done one (push-def) is
        // popped (no create for it).
        let creates = find_calls(&cl, "gh", &["pr", "create"]);
        assert_eq!(
            creates.len(),
            1,
            "done commit is popped, exactly one create"
        );
        assert!(
            creates
                .iter()
                .all(|c| c.1.contains(&"push-abc".to_string())),
            "only the open head is created"
        );
        assert!(
            !creates
                .iter()
                .any(|c| c.1.contains(&"push-def".to_string())),
            "the done head is never created"
        );

        // No edits for the done PR.
        let edits = find_calls(&cl, "gh", &["pr", "edit"]);
        assert_eq!(edits.len(), 1, "no graph rewrite for the done PR");
        assert!(
            edits
                .iter()
                .all(|c| c.1.contains(&"push-abc".to_string()) || c.1.contains(&"7".to_string())),
            "edits target only the open PR"
        );
    }

    /// Responder for `land`: push-def is done (merged, #8), push-abc open (#7).
    fn land_with_done_responder() -> Box<dyn Fn(&str, &[&str]) -> Result<String, RunnerError>> {
        Box::new(|program, args| {
            let has = |s: &str| args.iter().any(|a| a.contains(s));
            match (
                program,
                has("change_id.short"),
                has("bookmarks.first"),
                has("bookmarks.join"),
            ) {
                ("jj", true, _, _) => Ok("abc\ndef\n".into()),
                ("jj", _, true, _) => Ok("main".into()),
                ("jj", _, _, true) => Ok(if args[2] == "abc" {
                    "push-abc"
                } else {
                    "push-def"
                }
                .into()),
                _ => match (
                    program,
                    has("git"),
                    has("push"),
                    has("list"),
                    has("merged"),
                    has("closed"),
                    has("state"),
                    has("ready"),
                    has("merge"),
                ) {
                    ("jj", _, true, _, _, _, _, _, _) => Ok(String::new()),
                    // open pr_list (no --state): push-def -> #8, push-abc -> #7.
                    ("gh", _, _, true, _, _, _, _, _) if !has("state") => Ok(if has("push-def") {
                        "[{\"number\":8,\"url\":\"https://github.com/o/r/pull/8\"}]"
                    } else {
                        "[{\"number\":7,\"url\":\"https://github.com/o/r/pull/7\"}]"
                    }
                    .into()),
                    // pr_is_done --state merged: push-def done (#8); push-abc open.
                    ("gh", _, _, _, true, _, _, _, _) if has("push-def") => {
                        Ok("[{\"number\":8}]".into())
                    }
                    ("gh", _, _, _, true, _, _, _, _) => Ok("[]".into()),
                    ("gh", _, _, _, _, true, _, _, _) => Ok("[]".into()),
                    _ => Ok(String::new()),
                },
            }
        })
    }

    #[test]
    fn land_skips_already_merged_prs() {
        let calls: Rc<RefCell<Vec<(String, Vec<String>)>>> = Rc::new(RefCell::new(Vec::new()));
        let r = RecordingRunner {
            calls: calls.clone(),
            responder: land_with_done_responder(),
        };
        let c = Client::new(&r);
        c.land("origin").unwrap();
        let cl = calls.borrow().clone();

        // Only the open PR (#7 / push-abc) is merged; the done one (#8 / push-def)
        // is popped and never passed to `gh pr merge`.
        let m = merges(&cl);
        assert_eq!(m.len(), 1, "done PR is skipped, only one real merge");
        assert!(
            m[0].1.contains(&"7".to_string()),
            "the open PR (#7) is merged"
        );
        assert!(
            !m.iter().any(|mm| mm.1.contains(&"8".to_string())),
            "the already-merged PR (#8) is not re-merged"
        );
    }

    #[test]
    fn submit_resubmit_updates_existing_prs() {
        let calls: Rc<RefCell<Vec<(String, Vec<String>)>>> = Rc::new(RefCell::new(Vec::new()));
        let r = RecordingRunner {
            calls: calls.clone(),
            responder: Box::new(|program, args| {
                let has = |s: &str| args.iter().any(|a| a.contains(s));
                match (
                    program,
                    has("change_id.short"),
                    has("bookmarks.first"),
                    has("bookmarks.join"),
                ) {
                    ("jj", true, _, _) => Ok("abc\ndef\n".into()),
                    ("jj", _, true, _) => Ok("main".into()),
                    ("jj", _, _, true) => Ok(if args[2] == "abc" {
                        "push-abc"
                    } else {
                        "push-def"
                    }
                    .into()),
                    _ => match (
                        program,
                        has("git"),
                        has("push"),
                        has("description.first_line"),
                        has("description"),
                        has("list"),
                        has("create"),
                        has("edit"),
                        has("merged"),
                        has("closed"),
                        has("state"),
                    ) {
                        ("jj", _, _, true, _, _, _, _, _, _, _) => Ok("Title".into()),
                        ("jj", _, _, _, true, _, _, _, _, _, _) => Ok("Title\nBody".into()),
                        ("jj", _, true, _, _, _, _, _, _, _, _) => Ok(String::new()),
                        // open pr_list (no --state): push-abc -> #7, push-def -> #8.
                        ("gh", _, _, _, _, true, _, _, _, _, _) if !has("state") => {
                            Ok(if has("push-abc") {
                                "[{\"number\":7,\"url\":\"https://github.com/o/r/pull/7\"}]"
                            } else if has("push-def") {
                                "[{\"number\":8,\"url\":\"https://github.com/o/r/pull/8\"}]"
                            } else {
                                "[]"
                            }
                            .into())
                        }
                        ("gh", _, _, _, _, _, _, true, _, _, _) => Ok("[]".into()),
                        ("gh", _, _, _, _, _, _, _, true, _, _) => Ok("[]".into()),
                        // pr_create_num is never hit (both PRs exist).
                        ("gh", _, _, _, _, _, true, _, _, _, _) => {
                            Ok("https://github.com/o/r/pull/7".into())
                        }
                        _ => Ok(String::new()),
                    },
                }
            }),
        };
        let c = Client::new(&r);
        c.submit("origin").unwrap();
        let cl = calls.borrow().clone();

        assert!(
            find_calls(&cl, "gh", &["pr", "create"]).is_empty(),
            "resubmit edits existing PRs, does not create"
        );
        let edits = find_calls(&cl, "gh", &["pr", "edit"]);
        // Each existing PR is edited twice: once to update title/body (upsert),
        // once to rewrite the stack graph in the second pass.
        assert_eq!(edits.len(), 4, "two existing PRs -> two edits each");
        assert!(
            edits.iter().any(|c| c.1.contains(&"7".to_string())),
            "edits PR #7"
        );
        assert!(
            edits.iter().any(|c| c.1.contains(&"8".to_string())),
            "edits PR #8"
        );
    }

    #[test]
    fn land_merges_stack_in_graph_order_root_first() {
        let calls: Rc<RefCell<Vec<(String, Vec<String>)>>> = Rc::new(RefCell::new(Vec::new()));
        let r = RecordingRunner {
            calls: calls.clone(),
            // push-def->#8 (root), push-abc->#7 (dep); none done.
            responder: Box::new(|program, args| {
                let has = |s: &str| args.iter().any(|a| a.contains(s));
                match (
                    program,
                    has("change_id.short"),
                    has("bookmarks.first"),
                    has("bookmarks.join"),
                ) {
                    ("jj", true, _, _) => Ok("abc\ndef\n".into()),
                    ("jj", _, true, _) => Ok("main".into()),
                    ("jj", _, _, true) => Ok(if args[2] == "abc" {
                        "push-abc"
                    } else {
                        "push-def"
                    }
                    .into()),
                    _ => match (
                        program,
                        has("list"),
                        has("merged"),
                        has("closed"),
                        has("state"),
                        has("merge"),
                    ) {
                        // open pr_list (no --state): push-def -> #8, push-abc -> #7.
                        ("gh", true, _, _, _, _) if !has("state") => Ok(if has("push-abc") {
                            "[{\"number\":7,\"url\":\"https://github.com/o/r/pull/7\"}]"
                        } else {
                            "[{\"number\":8,\"url\":\"https://github.com/o/r/pull/8\"}]"
                        }
                        .into()),
                        ("gh", _, true, _, _, _) => Ok("[]".into()),
                        ("gh", _, _, true, _, _) => Ok("[]".into()),
                        _ => Ok(String::new()),
                    },
                }
            }),
        };
        let c = Client::new(&r);
        c.land("origin").unwrap();
        let cl = calls.borrow().clone();

        let m = merges(&cl);
        assert_eq!(m.len(), 2, "two PRs -> two merges, no create/edit");
        // Root (push-def, #8) must merge before its dependent (push-abc, #7).
        assert!(m[0].1.contains(&"8".to_string()), "root #8 merges first");
        assert!(m[1].1.contains(&"7".to_string()), "dep #7 merges second");
    }

    #[test]
    fn submit_keeps_bottom_pr_open_and_non_draft() {
        let calls: Rc<RefCell<Vec<(String, Vec<String>)>>> = Rc::new(RefCell::new(Vec::new()));
        let r = RecordingRunner {
            calls: calls.clone(),
            // Two-commit stack; open pr_list returns existing PRs (#8 root, #7 dep).
            responder: Box::new(|program, args| {
                let has = |s: &str| args.iter().any(|a| a.contains(s));
                match (
                    program,
                    has("change_id.short"),
                    has("bookmarks.first"),
                    has("bookmarks.join"),
                ) {
                    ("jj", true, _, _) => Ok("abc\ndef\n".into()),
                    ("jj", _, true, _) => Ok("main".into()),
                    ("jj", _, _, true) => Ok(if args[2] == "abc" {
                        "push-abc"
                    } else {
                        "push-def"
                    }
                    .into()),
                    _ => match (
                        program,
                        has("list"),
                        has("merged"),
                        has("closed"),
                        has("state"),
                        has("create"),
                    ) {
                        // open pr_list (no --state): push-def->#8, push-abc->#7.
                        ("gh", true, _, _, _, _) if !has("state") => Ok(if has("push-abc") {
                            "[{\"number\":7,\"url\":\"https://github.com/o/r/pull/7\"}]"
                        } else {
                            "[{\"number\":8,\"url\":\"https://github.com/o/r/pull/8\"}]"
                        }
                        .into()),
                        // pr_is_done (--state merged/closed): open PRs -> [].
                        ("gh", _, true, _, _, _) => Ok("[]".into()),
                        ("gh", _, _, true, _, _) => Ok("[]".into()),
                        _ => Ok(String::new()),
                    },
                }
            }),
        };
        let c = Client::new(&r);
        c.submit("origin").unwrap();
        let cl = calls.borrow().clone();

        // Defensive ready on the bottom PR (#8) at the end of submit.
        let readies = find_calls(&cl, "gh", &["pr", "ready"]);
        assert_eq!(readies.len(), 1, "submit un-drafts bottom once");
        assert!(readies[0].1.contains(&"8".to_string()), "bottom #8 readied");
    }

    #[test]
    fn close_un_drafts_bottom_then_closes_in_graph_order() {
        let calls: Rc<RefCell<Vec<(String, Vec<String>)>>> = Rc::new(RefCell::new(Vec::new()));
        let r = RecordingRunner {
            calls: calls.clone(),
            // push-def->#8 (root/bottom), push-abc->#7 (dep).
            responder: Box::new(|program, args| {
                let has = |s: &str| args.iter().any(|a| a.contains(s));
                match (
                    program,
                    has("change_id.short"),
                    has("bookmarks.first"),
                    has("bookmarks.join"),
                ) {
                    ("jj", true, _, _) => Ok("abc\ndef\n".into()),
                    ("jj", _, true, _) => Ok("main".into()),
                    ("jj", _, _, true) => Ok(if args[2] == "abc" {
                        "push-abc"
                    } else {
                        "push-def"
                    }
                    .into()),
                    _ => match (
                        program,
                        has("list"),
                        has("merged"),
                        has("closed"),
                        has("state"),
                        has("ready"),
                        has("merge"),
                    ) {
                        // open pr_list (no --state): push-def->#8, push-abc->#7.
                        ("gh", true, _, _, _, _, _) if !has("state") => Ok(if has("push-abc") {
                            "[{\"number\":7,\"url\":\"https://github.com/o/r/pull/7\"}]"
                        } else {
                            "[{\"number\":8,\"url\":\"https://github.com/o/r/pull/8\"}]"
                        }
                        .into()),
                        // pr_is_done (--state merged/closed): open PRs -> [].
                        ("gh", _, true, _, _, _, _) => Ok("[]".into()),
                        ("gh", _, _, true, _, _, _) => Ok("[]".into()),
                        _ => Ok(String::new()),
                    },
                }
            }),
        };
        let c = Client::new(&r);
        c.close("origin").unwrap();
        let cl = calls.borrow().clone();

        // Bottom (#8) is un-drafted exactly once.
        let readies = find_calls(&cl, "gh", &["pr", "ready"]);
        assert_eq!(readies.len(), 1, "bottom un-drafted once");
        assert!(readies[0].1.contains(&"8".to_string()), "bottom #8 readied");

        let closes = find_calls(&cl, "gh", &["pr", "close"]);
        // Exclude `pr list --state closed` (contains "close" as substring).
        let closes: Vec<_> = closes
            .into_iter()
            .filter(|(_, a)| !a.iter().any(|x| x.contains("list")))
            .collect();
        assert_eq!(closes.len(), 2, "two PRs -> two closes");
        // Root-first: bottom (#8) is closed last (after dep #7).
        assert!(
            closes[0].1.contains(&"7".to_string()),
            "dep #7 closes first"
        );
        assert!(
            closes[1].1.contains(&"8".to_string()),
            "bottom #8 closes last"
        );
        // The ready must precede every close.
        let i_ready = cl
            .iter()
            .position(|(p, a)| p == "gh" && a.contains(&"ready".into()))
            .unwrap();
        let i_first_close = cl
            .iter()
            .position(|(p, a)| p == "gh" && a.contains(&"close".into()))
            .unwrap();
        assert!(
            i_ready < i_first_close,
            "bottom un-drafted before any close"
        );
        // No merges happen during close. Exclude `pr list --state merged`.
        let real_merges = find_calls(&cl, "gh", &["pr", "merge"])
            .into_iter()
            .filter(|(_, a)| !a.iter().any(|x| x.contains("list")))
            .collect::<Vec<_>>();
        assert!(real_merges.is_empty(), "close does not merge");
    }
}
