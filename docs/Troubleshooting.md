<!-- owner: shikanime | zone: internal | purpose: known failure modes and fixes -->

# Troubleshooting

## `nix flake check` fails on eval

Pure eval breaks on the comin / Nix access-token wiring. Use
`nix flake check --accept-flake-config --no-pure-eval` (matches CI).

## ARM host build differs from x86_64

`fushi`/`minish`/`nemishi` (aarch64-linux) and the x86_64 nodes share profiles
but differ in the flake `systems` list. When touching
`modules/nixos/profiles/distributed.nix`, keep both architectures in mind.

## Secret does not decrypt

Confirm you hold the SOPS age key for the repo and that `sops.defaultSopsFile`
points at the right `secrets/<host>.enc.yaml`. Plaintext never lands in git —
change the encrypted source, not a generated fragment.

## `comin` does not pick up a change

Verify the host polls the expected flake ref and that the commit is on the
branch `comin` tracks. A local `nixos-rebuild switch` confirms the config
independent of `comin`.
