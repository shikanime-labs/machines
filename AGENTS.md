# Machines

Shikanime's machine configuration for NixOS, nix-darwin, and shared Home Manager
modules. Source of truth for every host Shikanime manages — see README for the
full directory layout.

**Language:** Nix **License:** Apache-2.0

## Stack

- Nix flakes (`nixos-unstable`) — system configuration
- flake-parts + devlib — flake composition
- sops-nix — encrypted secrets (`secrets/*.enc.yaml`)
- devenv — repository dev shell
- treefmt-nix — formatting (`nix fmt`)
- comin — declarative remote deployment

## Common Commands

- Dev shell: `nix develop` (or let direnv auto-load via `.envrc`)
- Format: `nix fmt`
- Check: `nix flake check --accept-flake-config --no-pure-eval`
- Build host:
  `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
- Switch: `sudo nixos-rebuild switch --flake .#<host>` /
  `darwin-rebuild switch --flake .#telsha`

## Secrets

- Never commit plaintext. Edit encrypted files with
  `sops secrets/<host>.enc.yaml`.
- Hosts point `sops.defaultSopsFile` at their own secret file; there is no
  repo-owned secret schema to edit.

## VCS & Commit Style

- Primary VCS is Jujutsu (`.jj`). The working copy is the commit: stamp it with
  `jj describe -m "<msg>"` and review with `jj diff --git`.
- Commits are DCO-signed and GPG-signed; add a `Reviewed-by:` trailer when
  pushing via git.
- One logical change per commit/PR.

## Stack Workflow

- Install the official GitHub extension once: `gh extension install github/gh-stack`
  (requires GitHub CLI ≥ 2.0; `gh stack` is in public preview and may change).
- Keep one logical change per PR; split large work into a stack of PRs.
- Create a stack: `gh stack init`, then `gh stack add` for each new branch, and
  commit on the active branch. `gh stack view` lists the stack.
- Submit/update: `gh stack submit` (add `--open` to open PRs, `--auto` to skip
  prompts). Resubmit after each change to refresh titles, bodies, and branches.
- Pull down an existing stack: `gh stack checkout <PR_NUMBER>` (also accepts a
  stack number, PR URL, or branch name).
- Rebase onto updated trunk: `gh stack rebase` (cascading), then `gh stack submit`.
- Land a stack: `gh stack merge` (interactive) or
  `gh stack merge <PR_NUMBER> --yes --squash` to merge up to a PR.
- Never `gh pr merge` on a stacked PR — only `gh stack merge` lands stacks.
- Never force-push stack branches; `gh stack` owns the branch pointers.

## Gotchas

- `nix flake check` needs `--accept-flake-config --no-pure-eval` (CI uses
  these); pure eval fails on the comin / Nix access-token wiring.
- ARM (`aarch64-linux`) and x86_64 hosts share profiles but differ in the flake
  `systems` list — keep both in mind when touching
  `modules/nixos/profiles/distributed.nix`.
