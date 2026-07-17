//! Binary entry point: parse the CLI and surface errors as a non-zero exit.

use clap::Parser;
use jj_switch::cli::{Cli, run};
use jj_switch::runner::OsRunner;
use std::process::exit;

/// Program entry point.
fn main() {
    let cli = Cli::parse();
    let runner = OsRunner::new();
    let client = jj_switch::jjplus::Client::new(&runner);
    if let Err(err) = run(cli, &client) {
        eprintln!("jjplus: error: {err}");
        exit(1);
    }
}
