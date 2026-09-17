# Contributing to Hakurei

Thanks for helping with the Touhou tactical MMO. This repo follows the devlib
conventions (`shikanime-studio/devlib`); read `AGENTS.md` and the `docs/agents/`
pipeline before your first change.

## Environment

```sh
direnv allow   # or: nix develop --no-pure-eval
```

The dev shell provides Rust, protoc, and the pre-commit hooks (gitlint,
trufflehog, action-validator).

## Commit style

Commits are enforced by the pre-commit hook (`gitlint`):

- Plain-text capitalized title, no conventional-commit prefix.
- Body with labels: `Design:`, `Related:`, `Closes #`.
- Markdown wrapped at 80 columns (`nix fmt`).
- DCO: every commit carries `Signed-off-by: Name <email>`.

### Stack workflow

- 1 commit == 1 PR via `ghstack`.
- Amend + `ghstack` to resubmit.
- `ghstack land` on the head PR to land the entire stack.
- Never `gh pr merge`, never force-push ghstack branches.
- `main` is protected: 1 approving review, linear history, signed commits,
  squash+rebase merge only.

## Validation gates

- `cargo test --workspace --exclude hakurei-server` green.
- `cargo test -p hakurei-server --test e2e_watch` against a fresh server.
- `nix flake check --impure` clean before submitting (`--impure` is required —
  devenv needs it to detect the project directory).
- Keep backward compatibility with consumer flakes.

## Feature pipeline (docs/agents/)

Issues are triaged (`needs-triage` → `ready-for-agent` / `ready-for-human`) and
flow through `to-spec` → `to-tickets` → implementation. The agent skills for
this pipeline are documented in `docs/agents/`.

## Design docs

Changes to mechanics should update the matching doc in `docs/design/`
(architecture, data-model, characters, roadmap) and the QA/KPI acceptance
criteria in `docs/design/qa.md` / `kpi.md` when behaviour is observable.
