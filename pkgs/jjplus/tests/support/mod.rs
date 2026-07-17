//! Shared integration harness: temp dirs, throwaway GitHub repos, a real `jj`
//! repo scaffold, and in-process `jjplus` CLI invocation. Gated by the
//! `integration` feature (included only from `integration.rs`).

#![cfg(feature = "integration")]

use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::atomic::{AtomicU64, Ordering};

use clap::Parser;
use jj_switch::cli::{self, Cli};
use jj_switch::github::Client;
use jj_switch::jjplus::Client as JjplusClient;
use jj_switch::runner::OsRunner;

/// Identity env vars for every `jj`/git invocation spawned in these tests.
const E2E_ENV: &[(&str, &str)] = &[
    ("JJ_USER", "jjplus-e2e"),
    ("JJ_EMAIL", "e2e@example.com"),
    ("GIT_AUTHOR_NAME", "jjplus-e2e"),
    ("GIT_AUTHOR_EMAIL", "e2e@example.com"),
    ("GIT_COMMITTER_NAME", "jjplus-e2e"),
    ("GIT_COMMITTER_EMAIL", "e2e@example.com"),
];

static TMP_N: AtomicU64 = AtomicU64::new(0);

/// A temp dir that cleans itself up on drop.
pub struct Tmp {
    dir: PathBuf,
}
impl Tmp {
    /// Allocate a unique temp dir (removed on drop).
    fn new(prefix: &str) -> Self {
        let base = std::env::temp_dir();
        let n = TMP_N.fetch_add(1, Ordering::SeqCst);
        let dir = base.join(format!("jjplus-e2e-{prefix}-{}-{}", std::process::id(), n));
        let _ = fs::remove_dir_all(&dir);
        fs::create_dir_all(&dir).expect("create temp dir");
        Tmp { dir }
    }
}
impl Drop for Tmp {
    /// Recursively delete the temp dir.
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.dir);
    }
}

/// Create a throwaway private GitHub repo; delete it on drop.
pub struct Repo {
    pub name: String,
    pub owner: String,
}
impl Repo {
    /// Create a throwaway private GitHub repo (deleted on drop).
    pub fn create(owner: &str) -> Self {
        static N: AtomicU64 = AtomicU64::new(0);
        let n = N.fetch_add(1, Ordering::SeqCst);
        let name = format!("jjplus-e2e-{}-{n}", std::process::id());
        let runner = OsRunner::new();
        let gh = Client::new(&runner);
        let mut created = false;
        for _ in 0..10 {
            if gh.repo_create(&name).is_ok() {
                created = true;
                break;
            }
            std::thread::sleep(std::time::Duration::from_secs(2));
        }
        assert!(created, "repo create failed (GitHub eventual consistency)");
        Repo {
            name: name.clone(),
            owner: owner.to_string(),
        }
    }

    /// SSH clone URL for the throwaway repo.
    pub fn clone_url(&self) -> String {
        format!("git@github.com:{}/{}.git", self.owner, self.name)
    }
}
impl Drop for Repo {
    /// Delete the throwaway repo on GitHub.
    fn drop(&mut self) {
        let runner = OsRunner::new();
        let _ = Client::new(&runner).repo_delete(&self.owner, &self.name);
    }
}

/// Authenticated GitHub login name (`gh api user`).
pub fn gh_me() -> String {
    let runner = OsRunner::new();
    Client::new(&runner)
        .me()
        .expect("gh not authenticated: run `gh auth login`")
}

/// Init a jj repo, point `origin` at the GitHub remote, and seed a base commit + trunk.
pub fn scaffold(remote_url: &str) -> (Tmp, PathBuf) {
    let tmp = Tmp::new("scaffold");
    let repo = tmp.dir.join("repo");

    let out = Command::new("jj")
        .args(["git", "init"])
        .arg(&repo)
        .output()
        .expect("jj git init");
    assert!(
        out.status.success(),
        "jj git init failed: {}",
        String::from_utf8_lossy(&out.stderr)
    );

    // Push an initial commit so there is a trunk() to stack onto.
    fs::write(repo.join("base.txt"), "base").unwrap();
    commit(&repo, "base commit");
    // Bookmark the described base commit (not the empty WC commit above it).
    let out = Command::new("jj")
        .args(["bookmark", "create", "-r", "@-", "main"])
        .current_dir(&repo)
        .env("JJ_USER", "jjplus-e2e")
        .env("JJ_EMAIL", "e2e@example.com")
        .output()
        .expect("jj bookmark create");
    assert!(
        out.status.success(),
        "bookmark create failed: {}",
        String::from_utf8_lossy(&out.stderr)
    );

    let out = Command::new("jj")
        .args(["git", "remote", "add", "origin"])
        .arg(remote_url)
        .current_dir(&repo)
        .output()
        .expect("jj git remote add");
    assert!(
        out.status.success(),
        "remote add failed: {}",
        String::from_utf8_lossy(&out.stderr)
    );
    // Push the base to main so trunk() resolves. GitHub repo creation is
    // eventually consistent; retry until pushable.
    let mut pushed = false;
    for _ in 0..10 {
        let out = Command::new("jj")
            .args(["git", "push", "--remote", "origin", "-b", "main"])
            .current_dir(&repo)
            .env("JJ_USER", "jjplus-e2e")
            .env("JJ_EMAIL", "e2e@example.com")
            .output()
            .expect("jj git push base");
        if out.status.success() {
            pushed = true;
            break;
        }
        std::thread::sleep(std::time::Duration::from_secs(2));
    }
    assert!(pushed, "base push to origin failed after retries");
    // Define trunk() = main so submit()'s revset resolves in this throwaway repo.
    let out = Command::new("jj")
        .args([
            "config",
            "set",
            "--repo",
            "revset-aliases.\"trunk()\"",
            "main",
        ])
        .current_dir(&repo)
        .output()
        .expect("jj config set trunk");
    assert!(
        out.status.success(),
        "trunk alias failed: {}",
        String::from_utf8_lossy(&out.stderr)
    );

    (tmp, repo)
}

/// Stage a marker file and create a jj commit.
pub fn commit(repo: &Path, message: &str) {
    fs::write(repo.join(format!("{message}.txt")), message).unwrap();
    let mut cmd = Command::new("jj");
    cmd.args(["commit", "-m", message]).current_dir(repo);
    for (k, v) in E2E_ENV {
        cmd.env(k, v);
    }
    let out = cmd.output().expect("jj commit");
    assert!(
        out.status.success(),
        "jj commit failed: {}",
        String::from_utf8_lossy(&out.stderr)
    );
}

/// Run the `jjplus` CLI in-process: build `Cli` from `args`, build a
/// `Client` scoped to `repo`'s cwd/env, and dispatch via `cli::run`.
pub fn run(repo: &Path, args: &[&str]) -> bool {
    let cli = Cli::parse_from(std::iter::once("jjplus").chain(args.iter().copied()));
    let runner = OsRunner {
        cwd: Some(repo.to_path_buf()),
        env: E2E_ENV
            .iter()
            .map(|(k, v)| ((*k).to_string(), (*v).to_string()))
            .collect(),
    };
    let client = JjplusClient::new(&runner);
    cli::run(cli, &client).is_ok()
}

/// List PRs for the throwaway repo as JSON.
pub fn list_prs(owner: &str, name: &str) -> String {
    let runner = OsRunner::new();
    Client::new(&runner)
        .pr_list_repo(owner, name)
        .expect("gh pr list")
}

/// List merged PRs for the throwaway repo as JSON.
pub fn list_prs_merged(owner: &str, name: &str) -> String {
    let runner = OsRunner::new();
    Client::new(&runner)
        .pr_list_repo_state(owner, name, "merged")
        .expect("gh pr list --state merged")
}

/// List closed PRs for the throwaway repo as JSON.
pub fn list_prs_closed(owner: &str, name: &str) -> String {
    let runner = OsRunner::new();
    Client::new(&runner)
        .pr_list_repo_state(owner, name, "closed")
        .expect("gh pr list --state closed")
}
