//! Integration tests: drive `jjplus` (in-process via `cli::run`, over the
//! harness in `support`) against a real `jj` repo with a real GitHub remote
//! and real `gh` auth.
//!
//! These tests mutate GitHub: they create a throwaway repo under the
//! authenticated account, push the stack, and open/close real PRs, then delete
//! the repo. They are gated behind the `integration` feature (cargo test
//! --features integration) so the default `cargo test` stays offline/fast.

#![cfg(feature = "integration")]

mod support;

use std::process::Command;

use support::{Repo, gh_me, list_prs, list_prs_closed, list_prs_merged, run, scaffold};

#[test]
fn e2e_close_closes_the_stack() {
    let me = gh_me();
    let repo = Repo::create(&me);
    let (_tmp, r) = scaffold(&repo.clone_url());
    common::commit(&r, "feature a");
    common::commit(&r, "feature b");

    let ok = run(&r, &["submit"]);
    assert!(ok, "submit failed");

    let ok = run(&r, &["close"]);
    assert!(ok, "close failed");

    // Closed PRs leave the open list; query CLOSED explicitly.
    let prs = list_prs_closed(&me, &repo.name);
    let closed = prs.matches("\"number\"").count();
    assert!(closed >= 1, "expected at least one CLOSED PR, got: {prs}");
}

#[test]
fn e2e_switch_by_name_creates_workspace() {
    let me = gh_me();
    let repo = Repo::create(&me);
    let (_tmp, r) = scaffold(&repo.clone_url());
    common::commit(&r, "work");

    let ok = run(&r, &["switch", "feature"]);
    assert!(ok, "switch by name failed");
    assert!(r.join("feature.xxx").is_dir(), "feature.xxx not created");
}

#[test]
fn e2e_switch_by_revision_uses_change_id() {
    let me = gh_me();
    let repo = Repo::create(&me);
    let (_tmp, r) = scaffold(&repo.clone_url());
    common::commit(&r, "work");

    let cid_out = Command::new("jj")
        .args(["log", "-r", "@", "--no-graph", "-T", "change_id.short()"])
        .current_dir(&r)
        .output()
        .unwrap();
    let cid = String::from_utf8_lossy(&cid_out.stdout).trim().to_string();
    assert!(!cid.is_empty());

    let ok = run(&r, &["switch", "-r", &cid]);
    assert!(ok, "switch -r failed");
    assert!(
        r.join(format!("{cid}.xxx")).is_dir(),
        "{cid}.xxx not created (repo={})",
        r.display()
    );
}

#[test]
fn e2e_remove_deletes_workspace() {
    let me = gh_me();
    let repo = Repo::create(&me);
    let (_tmp, r) = scaffold(&repo.clone_url());
    common::commit(&r, "work");

    let ok = run(&r, &["switch", "feature"]);
    assert!(ok);
    assert!(r.join("feature.xxx").is_dir());

    let ok = run(&r, &["remove", "feature"]);
    assert!(ok, "remove failed");
    assert!(!r.join("feature.xxx").exists(), "workspace not removed");
}

#[test]
fn e2e_submit_single_commit_creates_one_pr() {
    let me = gh_me();
    let repo = Repo::create(&me);
    let (_tmp, r) = scaffold(&repo.clone_url());
    common::commit(&r, "my feature");

    let ok = run(&r, &["submit"]);
    assert!(ok, "submit failed");

    let prs = list_prs(&me, &repo.name);
    let count = prs.matches("\"number\"").count();
    assert_eq!(count, 1, "expected 1 PR, got: {prs}");
    assert!(prs.contains("my feature"), "title missing: {prs}");
}

#[test]
fn e2e_submit_two_commit_stack_creates_two_prs() {
    let me = gh_me();
    let repo = Repo::create(&me);
    let (_tmp, r) = scaffold(&repo.clone_url());
    common::commit(&r, "feature a");
    common::commit(&r, "feature b");

    let ok = run(&r, &["submit"]);
    assert!(ok, "submit failed");

    let prs = list_prs(&me, &repo.name);
    let count = prs.matches("\"number\"").count();
    assert_eq!(count, 2, "expected 2 PRs for a 2-commit stack, got: {prs}");
    // The dependent PR must be a draft.
    assert!(
        prs.contains("\"isDraft\":true"),
        "dep PR not drafted: {prs}"
    );
}

#[test]
fn e2e_land_merges_the_stack() {
    let me = gh_me();
    let repo = Repo::create(&me);
    let (_tmp, r) = scaffold(&repo.clone_url());
    common::commit(&r, "feature a");
    common::commit(&r, "feature b");

    let ok = run(&r, &["submit"]);
    assert!(ok, "submit failed");

    let ok = run(&r, &["land"]);
    assert!(ok, "land failed");

    // Merged PRs leave the open list; query MERGED explicitly.
    let prs = list_prs_merged(&me, &repo.name);
    assert!(
        prs.contains("\"state\":\"MERGED\""),
        "expected both PRs MERGED, got: {prs}"
    );
    // Exactly two PRs (feature a, feature b), both merged.
    assert_eq!(
        prs.matches("\"number\"").count(),
        2,
        "two PRs merged: {prs}"
    );
}
