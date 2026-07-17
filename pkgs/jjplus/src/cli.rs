//! CLI definition and dispatch: maps `clap` subcommands onto `jjplus::Client`.
use clap::{Parser, Subcommand};
use std::error::Error;

use crate::jjplus::Client;

/// jj workspace helper.
#[derive(Parser)]
#[command(name = "jjplus", version, about = "jj workspace helper")]
pub struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Create a jj workspace via `jj workspace add`.
    /// Prints the new workspace's absolute path so the caller can `cd` into it.
    Switch {
        /// Workspace base name; the dir is `<name>.xxx`. Takes precedence over -r.
        name: Option<String>,

        /// Check out this jj revset into a workspace named by its change id
        #[arg(short, long)]
        revision: Option<String>,

        /// Create only; do not print the path (for `cd`)
        #[arg(short, long)]
        no_move: bool,
    },
    /// Checkout a pull request into a new jj workspace named by its head ref.
    /// Prints the new workspace's absolute path so the caller can `cd` into it.
    Checkout {
        /// Pull request URL (https://github.com/owner/repo/pull/<n>)
        url: String,

        /// Create only; do not print the path (for `cd`)
        #[arg(short, long)]
        no_move: bool,
    },
    /// Forget and delete a jj workspace created by `switch`/`checkout`
    Remove {
        /// Workspace base name; the dir is `<name>.xxx`
        name: String,
    },
    /// Push the whole stack and open/update a GitHub PR per commit (ghstack-style)
    Submit {
        /// GitHub remote to push to (default: origin)
        #[arg(short, long, default_value = "origin")]
        remote: String,
    },
    /// Merge the whole stack's PRs in graph order (root-first)
    Land {
        /// GitHub remote the PR heads were pushed to (default: origin)
        #[arg(short, long, default_value = "origin")]
        remote: String,
    },
    /// Un-draft the bottom PR, then close the whole stack (nearest `main` last)
    Close {
        /// GitHub remote the PR heads were pushed to (default: origin)
        #[arg(short, long, default_value = "origin")]
        remote: String,
    },
}

/// Parse the CLI and dispatch to the selected command using `client`.
/// Callers build `Cli` (e.g. `Cli::parse()`) and `Client` themselves.
pub fn run(cli: Cli, client: &Client) -> Result<(), Box<dyn Error>> {
    match cli.command {
        Commands::Switch {
            name,
            revision,
            no_move,
        } => {
            let name = name.unwrap_or_else(|| revision.clone().unwrap());
            if revision.is_some() {
                let cid = client.jj.resolve_change_id(revision.as_ref().unwrap())?;
                client.switch(&name, no_move, Some(&cid))
            } else {
                client.switch(&name, no_move, None)
            }
        }
        Commands::Checkout { url, no_move } => client.checkout(&url, no_move),
        Commands::Remove { name } => client.remove(&name),
        Commands::Submit { remote } => client.submit(&remote),
        Commands::Land { remote } => client.land(&remote),
        Commands::Close { remote } => client.close(&remote),
    }
}
