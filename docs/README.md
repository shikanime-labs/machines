<!-- owner: Automata | zone: technical | purpose: Canonical technical index for machines, the fleet NixOS and nix-darwin configuration repository -->
# Machines

The source of truth for Shikanime's machines: host-specific NixOS and
nix-darwin configurations, shared system and Home Manager module layers,
`sops-nix` encrypted secrets, distributed build/deployment helpers, and a
devenv shell for repo tooling. `flake.nix` composes it all through flake-parts.

## Hosts

Per-machine entry points live in `hosts/<name>/`; `facter.json` stores hardware
facts where `nixos-facter` is used.

- NixOS servers: `ashira`, `manash`, `nalsha` (x86_64, Beelink cluster)
- ARM nodes: `fushi`, `minish` (RPi4), `nemishi` (RPi5)
- Inference nodes: `kushira`, `sashina` (Minisforum MS-S1 Max / Strix Halo,
  ROCm)
- Workstation: `nixtar` (Razer Blade 17, Hyprland on Wayland + NVIDIA)
- `automata` &mdash; KubeVirt containerdisk (NixOS qcow2 wrapped as an OCI image)
- Darwin: `telsha` (`hosts/telsha/darwin-configuration.nix`)

## Flake entry point

`modules/flake/` holds the flake-parts glue:

- `nixos.nix` &mdash; every `nixosConfigurations.*` host plus the `automata` and
  hermes-agent OCI/containerdisk eval packages
- `darwin.nix` &mdash; `darwinConfigurations.telsha`
- `devenv.nix`, `packages.nix` &mdash; dev shell and tooling outputs

Supported systems: `x86_64-linux`, `aarch64-linux`, `aarch64-darwin`.

## Shared profiles

Hosts are minimal; `modules/nixos/profiles/` and `modules/darwin/profiles/`
carry the real configuration, layered by composition:

- `minimal.nix` &mdash; Home Manager defaults, weekly Nix GC/optimise
- `base.nix` &mdash; imports `minimal`, Colemak at OS level, flake features,
  sops-template Nix config
- `server.nix`, `workstation.nix`, `graphical.nix` &mdash; role layers
- `nishir.nix` &mdash; cluster-node profile: `br0` bridge, comin against GitHub
  and Forgejo on a 600 s poll, node_exporter/vmagent metrics, firewall, imports
  `ai`/`distributed`/`forgejo`/`server`/`wifi` and builder/nishir users
- `distributed.nix` &mdash; remote build machines (workstations intentionally
  omit comin and deploy manually)
- `ai.nix` / `agent.nix` &mdash; hermes-agent and computer-use wiring via
  `cua-driver`
- `automata.nix` &mdash; KubeVirt guest profile, wires the honcho memory plugin
  onto hermes-agent

## Hardware composition

`modules/flake/nixos.nix` groups hardware modules per machine class: Beelink
cluster (common-cpu-intel + common-pc-ssd), MS-S1 Max (common-cpu-amd +
common-gpu-amd with `rocmSupport = true`), RPi cluster (`rpi4`/`rpi5`), and the
Nixtar workstation (Intel + NVIDIA). Darwin uses `nix-darwin`.

## Secrets

`sops-nix` with `secrets/*.enc.yaml`; hosts point `sops.defaultSopsFile` at
their own file and use systemd restart hooks / `sops.templates.*` where needed.
There is no repo-owned secret schema &mdash; never commit plaintext.

## Deployment

- comin is the sole fleet deployer on cluster nodes, pulling the flake from
  GitHub and a Forgejo mirror and switching automatically; workstations deploy
  manually.
- `automata` ships as `packages.<system>.automata-oci-image` (NixOS qcow2 in an
  OCI image) and runs as a KubeVirt VM.
- `hermes-agent` ships as `packages.<system>.hermes-agent-oci-image`
  (dockerTools, entrypoint `hermes gateway`, `HERMES_HOME=/var/lib/hermes`,
  port 8644) from the shared `pkgs/hermes-agent` derivation used by the host
  service.

## Usage

```
nix build .#nixosConfigurations.manash.config.system.build.toplevel
sudo nixos-rebuild switch --flake .#manash
darwin-rebuild switch --flake .#telsha
nix develop
```

Noctalia theming is configured entirely in Nix under
`programs.noctalia.settings` in per-user Home Manager config &mdash; there is no
repo-owned theme schema.

## Repository layout

- `hosts/` &mdash; per-machine configurations and hardware facts
- `modules/nixos/`, `modules/darwin/`, `modules/home/`, `modules/flake/` &mdash;
  shared module layers and flake glue
- `secrets/` &mdash; `*.enc.yaml` encrypted secrets
- `infra/` &mdash; Terraform for GitHub, Google Cloud, and HCP
- `pkgs/` &mdash; shared derivations (e.g. hermes-agent)
- `skaffold.yaml` &mdash; render/build automation
- `docs/` &mdash; this canonical index plus host-specific guides

## Canonical sources

- [Repository README](https://github.com/shikanime-labs/machines#readme)
- [Technical wiki](https://github.com/shikanime-labs/machines/wiki)
  ([Architecture](https://github.com/shikanime-labs/machines/wiki/Architecture),
  [Operations](https://github.com/shikanime-labs/machines/wiki/Operations),
  [Troubleshooting](https://github.com/shikanime-labs/machines/wiki/Troubleshooting))

In-repo `docs/` is canonical for technical detail; the wiki is a rendered human
index that links here.
