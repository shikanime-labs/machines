//! Run external VCS programs (`jj`, `gh`) behind a `Runner` trait so the
//! high-level clients can be faked in tests.
use std::path::PathBuf;
use std::process::Command;

/// Unified error type for VCS operations. A plain string so fake runners can
/// return canned errors and tests can assert on them.
pub type RunnerError = String;

/// Abstraction over running an external program. Implemented by `OsRunner`
/// (real) and `FnRunner` (tests).
pub trait Runner {
    /// Run `program` with `args`, returning stdout on success.
    fn run(&self, program: &str, args: &[&str]) -> Result<String, RunnerError>;
}

/// Real runner: shells out via `std::process::Command`. Optionally scoped to a
/// working directory and/or extra environment (used by the e2e tests to run
/// the CLI in-process against a temp repo without spawning the binary).
pub struct OsRunner {
    /// If set, every spawned program runs with this as its working directory.
    pub cwd: Option<PathBuf>,
    /// Extra environment variables merged into every spawned program.
    pub env: Vec<(String, String)>,
}
impl OsRunner {
    /// Runner that inherits the current process cwd/env (production default).
    pub fn new() -> Self {
        OsRunner {
            cwd: None,
            env: Vec::new(),
        }
    }
}
impl Default for OsRunner {
    fn default() -> Self {
        Self::new()
    }
}
impl Runner for OsRunner {
    /// Shell out via `std::process::Command`; fails on a non-zero exit.
    fn run(&self, program: &str, args: &[&str]) -> Result<String, RunnerError> {
        let mut cmd = Command::new(program);
        cmd.args(args);
        if let Some(cwd) = &self.cwd {
            cmd.current_dir(cwd);
        }
        for (k, v) in &self.env {
            cmd.env(k, v);
        }
        let out = cmd.output().map_err(|e| e.to_string())?;
        if !out.status.success() {
            return Err(format!(
                "`{program} {}` failed: {}",
                args.join(" "),
                String::from_utf8_lossy(&out.stderr).trim()
            ));
        }
        Ok(String::from_utf8_lossy(&out.stdout).to_string())
    }
}

/// Test runner backed by a closure.
#[cfg(test)]
pub struct FnRunner {
    pub f: Box<dyn Fn(&str, &[&str]) -> Result<String, RunnerError>>,
}
#[cfg(test)]
impl Runner for FnRunner {
    fn run(&self, program: &str, args: &[&str]) -> Result<String, RunnerError> {
        (self.f)(program, args)
    }
}
