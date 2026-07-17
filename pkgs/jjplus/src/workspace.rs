//! Workspace checkout/removal: `checkout` (PR -> workspace) and `remove`.
//!
//! `switch` stays on `jjplus::Client` but reuses `workspace_path` here so the
//! `<name>.xxx` convention lives in exactly one place.
use crate::jjplus::Client;
use std::error::Error;
use std::path::PathBuf;

/// `<name>` -> `<name>.xxx` (ponytail: fixed `.xxx` convention, no --path).
pub(crate) fn workspace_path(name: &str) -> PathBuf {
    let mut p = PathBuf::from(name);
    p.set_extension("xxx");
    p
}

/// Checkout a pull request into a new workspace named by its head ref.
/// Prints the new workspace's absolute path unless `no_move`.
pub fn checkout(client: &Client, url: &str, no_move: bool) -> Result<(), Box<dyn Error>> {
    let head = client.gh.pr_view_head(url)?;
    client.jj.git_fetch()?;
    let path = workspace_path(&head);
    let path_str = path.to_string_lossy().to_string();
    client.jj.workspace_add(&head, Some(&path_str))?;
    if !no_move {
        println!("{}", path.display());
    }
    Ok(())
}

/// Forget and delete a workspace created by `switch`/`checkout`.
pub fn remove(client: &Client, name: &str) -> Result<(), Box<dyn Error>> {
    let path = workspace_path(name);
    let path_str = path.to_string_lossy().to_string();
    client.jj.workspace_forget(&path_str)?;
    Ok(())
}
