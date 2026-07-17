//! High-level `jj` wrapper: workspace add/forget, log queries, and git push/fetch.
use crate::runner::{Runner, RunnerError};

/// High-level `jj` wrapper.
pub struct Client<'a> {
    runner: &'a dyn Runner,
}
impl<'a> Client<'a> {
    /// Build a `jj` client over the given runner.
    pub fn new(runner: &'a dyn Runner) -> Self {
        Client { runner }
    }

    /// Add a workspace at `path`, optionally checked out at `rev`.
    pub fn workspace_add(&self, path: &str, rev: Option<&str>) -> Result<(), RunnerError> {
        let mut args = vec!["workspace", "add"];
        if let Some(r) = rev {
            args.push("-r");
            args.push(r);
        }
        args.push(path);
        self.runner.run("jj", &args).map(|_| ())
    }

    /// Forget the workspace rooted at `path`.
    pub fn workspace_forget(&self, path: &str) -> Result<(), RunnerError> {
        self.runner
            .run("jj", &["workspace", "forget", path])
            .map(|_| ())
    }

    /// Run `jj log` and return the template output for `revset`.
    pub fn log(&self, revset: &str, template: &str) -> Result<String, RunnerError> {
        self.runner
            .run("jj", &["log", "-r", revset, "--no-graph", "-T", template])
    }

    /// Resolve the configured push-bookmark prefix from
    /// `templates.git_push_bookmark` (e.g. `"shikanime/push-" ++ change_id.short()`
    /// -> `shikanime/push-`). Falls back to `push-` if unset or not in the
    /// expected `… ++ change_id.short()` shape.
    pub fn push_bookmark_prefix(&self) -> Result<String, RunnerError> {
        let raw = self
            .runner
            .run("jj", &["config", "get", "templates.git_push_bookmark"])
            .unwrap_or_default();
        let raw = raw.trim();
        if let Some((prefix, _)) = raw.split_once("++") {
            let prefix = prefix.trim().trim_matches('"').trim();
            if !prefix.is_empty() {
                return Ok(prefix.to_string());
            }
        }
        Ok("push-".to_string())
    }

    /// Push `rev` to `remote` (jj creates a `push-<change>` bookmark).
    pub fn git_push(&self, rev: &str, remote: &str) -> Result<(), RunnerError> {
        self.runner
            .run("jj", &["git", "push", "-c", rev, "--remote", remote])
            .map(|_| ())
    }

    /// Fetch from the configured git remote.
    pub fn git_fetch(&self) -> Result<(), RunnerError> {
        self.runner.run("jj", &["git", "fetch"]).map(|_| ())
    }

    /// Resolve a revset to exactly one commit's short change id.
    pub fn resolve_change_id(&self, revset: &str) -> Result<String, RunnerError> {
        let out = self.log(revset, "change_id.short()")?;
        let ids: Vec<&str> = out
            .lines()
            .map(str::trim)
            .filter(|l| !l.is_empty())
            .collect();
        match ids.len() {
            0 => Err(format!("revset `{revset}` resolves to no commits")),
            1 => Ok(ids[0].to_string()),
            n => Err(format!(
                "revset `{revset}` resolves to {n} commits; pass a single commit"
            )),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::runner::FnRunner;

    #[test]
    fn resolve_single_change_id() {
        let r = FnRunner {
            f: Box::new(|_, a| {
                if a.contains(&"-r") {
                    Ok("abc123\n".into())
                } else {
                    Ok(String::new())
                }
            }),
        };
        let jj = Client::new(&r);
        assert_eq!(jj.resolve_change_id("@").unwrap(), "abc123");
    }

    #[test]
    fn push_bookmark_prefix_reads_config() {
        let r = FnRunner {
            f: Box::new(|_, a| {
                if a.contains(&"templates.git_push_bookmark") {
                    Ok("\"shikanime/push-\" ++ change_id.short()\n".into())
                } else {
                    Ok(String::new())
                }
            }),
        };
        let jj = Client::new(&r);
        assert_eq!(jj.push_bookmark_prefix().unwrap(), "shikanime/push-");
    }

    #[test]
    fn push_bookmark_prefix_falls_back() {
        let r = FnRunner {
            f: Box::new(|_, _| Ok(String::new())),
        };
        let jj = Client::new(&r);
        assert_eq!(jj.push_bookmark_prefix().unwrap(), "push-");
    }

    #[test]
    fn resolve_multiple_change_ids_errors() {
        let r = FnRunner {
            f: Box::new(|_, _| Ok("a\nb\n".into())),
        };
        let jj = Client::new(&r);
        assert!(jj.resolve_change_id("@").is_err());
    }
}
