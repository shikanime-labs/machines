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
- Nix style: dotted assignment (`a.b.c = v;`) for a single leaf under a shared
  parent key; a record literal (`a = { b = …; c = …; };`) once two or more keys
  share that parent, with keys sorted. Run `nix fmt` before committing.
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


## Gotchas

- `nix flake check` needs `--accept-flake-config --no-pure-eval` (CI uses
  these); pure eval fails on the comin / Nix access-token wiring.
- ARM (`aarch64-linux`) and x86_64 hosts share profiles but differ in the flake
  `systems` list — keep both in mind when touching
  `modules/nixos/profiles/distributed.nix`.
- Every host vmagent scrape of a localhost exporter must relabel
  `instance` to `config.networking.hostName` (plus a `cluster` label):
  `127.0.0.1` targets otherwise merge every host into one series and per-host
  rates are garbage. The node-exporter and comin jobs are the pattern.
