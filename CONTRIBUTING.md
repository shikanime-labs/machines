# Contributing to machines

NixOS, nix-darwin, and WSL machine configurations for Shikanime

## Workflow

Fork, branch off `main`, open a PR against `main`. One logical change per PR.

## Environment

```sh
direnv allow  # or: nix develop
```

## Validation

`nix flake check` green; test host evals before submitting.

Security issues: see [SECURITY.md](SECURITY.md).
