# Machines

Shikanime's machine configuration for NixOS, nix-darwin, WSL, and shared Home
Manager modules. Source of truth for every host Shikanime manages — see README
for the full directory layout.

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

- Open a PR; land it by commenting `.land` (or `.force-land`). Never
  `gh pr merge`. Never force-push the PR branch.
- `.rebase` rebase on base, `.backport` backport, `.close` abort, `.run` trigger
  CI.
- `main` is protected: requires a passing status check and a PR; linear history.

## Gotchas

- `nix flake check` needs `--accept-flake-config --no-pure-eval` (CI uses
  these); pure eval fails on the comin / Nix access-token wiring.
- ARM (`aarch64-linux`) and x86_64 hosts share profiles but differ in the flake
  `systems` list — keep both in mind when touching
  `modules/nixos/profiles/distributed.nix`.
