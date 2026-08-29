<!-- owner: shikanime | zone: internal | purpose: machine config architecture -->

# Architecture

`machines` is the Nix flake source of truth for every host Shikanime manages —
NixOS, nix-darwin, and shared Home Manager modules. The working copy is the
system; `comin` declaratively deploys it to hosts.

## Layers

- `flake.nix` — entry point; imports module sets and exposes host configs and
  build outputs (flake-parts + devlib).
- `hosts/` — per-machine entry points:
  - `hosts/<name>/configuration.nix` — NixOS host
  - `hosts/telsha/darwin-configuration.nix` — nix-darwin host
  - `hosts/<name>/users/<user>/home-configuration.nix` — Home Manager
  - `hosts/<name>/facter.json` — hardware facts for `nixos-facter` hosts
- `modules/` — shared profiles:
  - `modules/nixos/` — `base`, `minimal`, `workstation`, `follower`,
    `distributed`, `nishir`/`talashi` cluster profiles, `ai` (hermes-agent +
    computer-use `cua-driver`)
  - `modules/darwin/` — macOS host profiles
  - `modules/home/` — shared Home Manager modules
  - `modules/flake/` — flake-parts glue
- `secrets/` — `sops-nix` encrypted `*.enc.yaml`; decrypted at eval/activation.
- `infra/`, `pkgs/`, `skaffold.yaml` — cluster glue, local packages, automation.

## Hosts

`ashira`, `manash`, `nalsha` (x86_64 servers), `fushi`, `minish`, `nemishi`
(ARM), `kushira`/`sashina` (Strix Halo inference), `nixtar` (GUI workstation),
`catbox` (KubeVirt containerdisk), `telsha` (nix-darwin).

## Deployment

`comin` pulls the flake and switches each host; ARM and x86_64 share profiles
but differ in the flake `systems` list.
