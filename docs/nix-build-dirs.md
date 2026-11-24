# Nix build dirs on the RPi build peers

Nix unpacks and builds derivations under `/nix/var/nix/builds` by default. On the
RPi build peers that path lives on the SD card, which is slow and small, so the
fleet redirects it to the external disk each host already mounts via disko.

## The pattern

The redirect is done with `systemd.tmpfiles.rules`, not with Nix configuration:

```nix
systemd.tmpfiles.rules = [
  "d /mnt/marisa/nix/builds 0755 root root -"
  "L+ /nix/var/nix/builds - - - - /mnt/marisa/nix/builds"
];
```

- The `d` rule creates the target directory on the external disk first.
- The `L+` rule creates a symlink at the default path pointing at it. `L+`
  replaces an existing regular directory or symlink, so the swap converges even
  on hosts where Nix already created a real `/nix/var/nix/builds`.

The rule order matters: `d` must precede `L+` so the target exists before the
symlink points at it. The `d` rule is required, not cosmetic — Nix calls
`createDirs` on the symlink and throws `EEXIST` when the target is missing.

This supersedes setting `nix.settings.build-dir` per host (landed in #1759,
replaced by #1765): no Nix configuration is changed, and the redirect is
visible as a plain filesystem link managed by tmpfiles.

## Per-host targets

| Host | External disk (disko) | Build dir target |
| --- | --- | --- |
| fushi | `/mnt/marisa` | `/mnt/marisa/nix/builds` |
| minish | `/mnt/reimu` | `/mnt/reimu/nix/builds` |
| nemishi | `/mnt/data` | `/mnt/data/nix/builds` |

The rules live in each host's `modules/nixos/hosts/<host>/configuration.nix`.

## References

- PR #1765 — Link the default Nix build dir to the RPi external disks
- PR #1759 — the superseded `nix.settings.build-dir` approach
