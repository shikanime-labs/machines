<!-- owner: shikanime | zone: internal | purpose: flake outputs and command surface -->

# Reference

## Flake outputs

- `nixosConfigurations.<host>` for `ashira`, `manash`, `nalsha`, `fushi`,
  `minish`, `nemishi`, `kushira`, `sashina`, `nixtar`
- `darwinConfigurations.telsha`
- `packages.<system>.*` — including `catbox` (KubeVirt containerdisk)

## Key commands

| Command                                                               | Purpose               |
| --------------------------------------------------------------------- | --------------------- |
| `nix develop`                                                         | enter dev shell       |
| `nix fmt`                                                             | format the repo       |
| `nix flake check --accept-flake-config --no-pure-eval`                | validate flake        |
| `nix build .#nixosConfigurations.<host>.config.system.build.toplevel` | build host            |
| `sudo nixos-rebuild switch --flake .#<host>`                          | switch NixOS host     |
| `darwin-rebuild switch --flake .#telsha`                              | switch darwin host    |
| `sops secrets/<host>.enc.yaml`                                        | edit encrypted secret |

## Module map

- `modules/nixos/` — `base`, `minimal`, `workstation`, `follower`,
  `distributed`, `nishir`, `talashi`, `ai`
- `modules/darwin/` — `base`, `minimal`, `workstation`, `distributed`
- `modules/home/` — shell, editor, font, VCS, workstation settings
- `modules/flake/` — flake-parts glue
