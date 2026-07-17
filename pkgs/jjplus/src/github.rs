//! High-level `gh` wrapper: PR view/create/edit, repo view, and draft patching.
use crate::runner::{Runner, RunnerError};
use serde::Deserialize;

/// One entry from `gh pr list --json number,url`.
#[derive(Debug, Deserialize)]
pub struct PrListItem {
    pub number: u64,
    pub url: String,
}

/// High-level `gh` wrapper.
pub struct Client<'a> {
    runner: &'a dyn Runner,
}
impl<'a> Client<'a> {
    /// Build a `gh` client over the given runner.
    pub fn new(runner: &'a dyn Runner) -> Self {
        Client { runner }
    }

    /// Resolve a PR URL to its head ref name (`headRefName`).
    pub fn pr_view_head(&self, url: &str) -> Result<String, RunnerError> {
        self.runner
            .run(
                "gh",
                &[
                    "pr",
                    "view",
                    url,
                    "--json",
                    "headRefName",
                    "-q",
                    ".headRefName",
                ],
            )
            .map(|s| s.trim().to_string())
    }

    /// List PRs whose head ref is `head`, returning parsed entries.
    pub fn pr_list(&self, head: &str) -> Result<Vec<PrListItem>, RunnerError> {
        let raw = self.runner.run(
            "gh",
            &["pr", "list", "--head", head, "--json", "number,url"],
        )?;
        serde_json::from_str(&raw).map_err(|e| format!("parse pr list: {e}"))
    }

    /// Open a PR from `head` into `base` with `title`/`body`; `--draft` when `draft`.
    pub fn pr_create(
        &self,
        title: &str,
        body: &str,
        head: &str,
        base: &str,
        draft: bool,
    ) -> Result<String, RunnerError> {
        let mut args = vec![
            "pr", "create", "--title", title, "--body", body, "-H", head, "-B", base,
        ];
        if draft {
            args.push("--draft");
        }
        self.runner.run("gh", &args).map(|s| s.trim().to_string())
    }

    /// Open a PR from `head` into `base`; `--draft` when `draft`. Returns its number.
    pub fn pr_create_num(
        &self,
        title: &str,
        body: &str,
        head: &str,
        base: &str,
        draft: bool,
    ) -> Result<u64, RunnerError> {
        let mut args = vec![
            "pr", "create", "--title", title, "--body", body, "-H", head, "-B", base,
        ];
        if draft {
            args.push("--draft");
        }
        let raw = self.runner.run("gh", &args)?;
        // `gh pr create` prints the PR URL, e.g.
        // "https://github.com/owner/repo/pull/42".
        raw.trim()
            .rsplit('/')
            .next()
            .and_then(|n| n.parse::<u64>().ok())
            .ok_or_else(|| format!("parse pr number from url: {raw}"))
    }

    /// Update the title/body of PR `num`.
    pub fn pr_edit(&self, num: u64, title: &str, body: &str) -> Result<(), RunnerError> {
        self.runner
            .run(
                "gh",
                &[
                    "pr",
                    "edit",
                    &num.to_string(),
                    "--title",
                    title,
                    "--body",
                    body,
                ],
            )
            .map(|_| ())
    }

    /// Squash-merge PR `num` via `gh pr merge --squash`.
    pub fn pr_merge(&self, num: u64) -> Result<(), RunnerError> {
        self.runner
            .run("gh", &["pr", "merge", &num.to_string(), "--squash"])
            .map(|_| ())
    }

    /// Mark PR `num` ready for review (clears draft status) via `gh pr ready`.
    pub fn pr_ready(&self, num: u64) -> Result<(), RunnerError> {
        self.runner
            .run("gh", &["pr", "ready", &num.to_string()])
            .map(|_| ())
    }

    /// Close PR `num` via `gh pr close` (does not delete the branch).
    pub fn pr_close(&self, num: u64) -> Result<(), RunnerError> {
        self.runner
            .run("gh", &["pr", "close", &num.to_string()])
            .map(|_| ())
    }

    /// Resolve the current repo as `owner/name`.
    pub fn repo_view(&self) -> Result<String, RunnerError> {
        self.runner
            .run(
                "gh",
                &[
                    "repo",
                    "view",
                    "--json",
                    "nameWithOwner",
                    "-q",
                    ".nameWithOwner",
                ],
            )
            .map(|s| s.trim().to_string())
    }

    /// Convert PR `num` into a draft via the GitHub REST API.
    pub fn api_patch_draft(&self, repo: &str, num: u64) -> Result<(), RunnerError> {
        self.runner
            .run(
                "gh",
                &[
                    "api",
                    "-X",
                    "PATCH",
                    &format!("repos/{repo}/pulls/{num}"),
                    "-f",
                    "draft=true",
                ],
            )
            .map(|_| ())
    }

    /// Authenticated GitHub login name via `gh api user`.
    pub fn me(&self) -> Result<String, RunnerError> {
        self.runner
            .run("gh", &["api", "user", "--jq", ".login"])
            .map(|s| s.trim().to_string())
    }

    /// Create a private throwaway repo via `gh repo create`.
    pub fn repo_create(&self, name: &str) -> Result<String, RunnerError> {
        self.runner
            .run(
                "gh",
                &[
                    "repo",
                    "create",
                    name,
                    "--private",
                    "--description",
                    "jjplus e2e throwaway",
                ],
            )
            .map(|s| s.trim().to_string())
    }

    /// Delete `owner/name` via `gh repo delete -y`.
    pub fn repo_delete(&self, owner: &str, name: &str) -> Result<(), RunnerError> {
        self.runner
            .run("gh", &[format!("{owner}/{name}").as_str(), "-y"])
            .map(|_| ())
    }

    /// List PRs for `owner/name` as raw JSON.
    pub fn pr_list_repo(&self, owner: &str, name: &str) -> Result<String, RunnerError> {
        self.runner
            .run(
                "gh",
                &[
                    "pr",
                    "list",
                    "--repo",
                    &format!("{owner}/{name}"),
                    "--json",
                    "number,url,title,isDraft,state",
                ],
            )
            .map(|s| s.trim().to_string())
    }

    /// List PRs for `owner/name` filtered by `--state` as raw JSON.
    pub fn pr_list_repo_state(
        &self,
        owner: &str,
        name: &str,
        state: &str,
    ) -> Result<String, RunnerError> {
        self.runner
            .run(
                "gh",
                &[
                    "pr",
                    "list",
                    "--repo",
                    &format!("{owner}/{name}"),
                    "--state",
                    state,
                    "--json",
                    "number,url,title,isDraft,state",
                ],
            )
            .map(|s| s.trim().to_string())
    }

    /// True if `head` already has a closed or merged PR — i.e. it is "done"
    /// and should be popped out of the active stack on `submit`/`land`/`close`
    /// (ghstack errors if you try to reopen or re-merge an already-landed PR).
    ///
    /// Checks both `merged` and `closed` states; an open PR returns false.
    /// A non-JSON or empty reply for a state is treated as "no PR in
    /// this state" (lenient) so a missing/empty `gh` response can't
    /// abort `submit`/`land`/`close`.
    pub fn pr_is_done(&self, head: &str) -> Result<bool, RunnerError> {
        for state in ["merged", "closed"] {
            let raw = self.runner.run(
                "gh",
                &[
                    "pr", "list", "--head", head, "--state", state, "--json", "number",
                ],
            )?;
            // A valid non-empty list means a PR exists in this state => done.
            if let Ok(v) = serde_json::from_str::<Vec<serde_json::Value>>(&raw) {
                if !v.is_empty() {
                    return Ok(true);
                }
            }
        }
        Ok(false)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::runner::FnRunner;

    #[test]
    fn pr_view_head_trims() {
        let r = FnRunner {
            f: Box::new(|_, _| Ok("  patch-1\n".into())),
        };
        let gh = Client::new(&r);
        assert_eq!(gh.pr_view_head("https://x/1").unwrap(), "patch-1");
    }

    #[test]
    fn me_trims_login() {
        let r = FnRunner {
            f: Box::new(|_, _| Ok("  octocat\n".into())),
        };
        let gh = Client::new(&r);
        assert_eq!(gh.me().unwrap(), "octocat");
    }
}
