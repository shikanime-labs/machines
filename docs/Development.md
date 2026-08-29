<!-- owner: shikanime | zone: internal | purpose: local setup and build/switch loop -->

# Development

## Prerequisites

- Nix with flakes enabled, `direnv`, and the repo's SOPS age key to read
  `secrets/`.

## Local loop

1. `direnv allow` (or `nix develop`) to enter the dev shell.
2. Edit host/module Nix; keep one logical change per commit.
3. `nix fmt` to format.
4. `nix flake check --accept-flake-config --no-pure-eval` — the flags are
   required (pure eval fails on comin / Nix access-token wiring).

## Build and switch

```sh
# build a host's toplevel
nix build .#nixosConfigurations.manash.config.system.build.toplevel
# switch a NixOS host
sudo nixos-rebuild switch --flake .#manash
# switch the darwin host
darwin-rebuild switch --flake .#telsha
```

## VCS

Primary VCS is Jujutsu (`.jj`): `jj describe -m "<msg>"` stamps the working
copy, `jj diff --git` reviews. Commits are DCO- and GPG-signed; add a
`Reviewed-by:` trailer when pushing via git. Large work splits into a `gh stack`
of PRs.
