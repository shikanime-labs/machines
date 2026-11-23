# Rootless Docker on the automata guest

The automata containerdisk guest runs Docker in rootless mode:

```nix
virtualisation.docker = {
  autoPrune.enable = true;
  rootless = {
    enable = true;
    setSocketVariable = true;
  };
};
```

(wiring in `modules/nixos/profiles/automata.nix`).

Rootless Docker runs the daemon as the invoking user — on automata that is
`hermes` — and requires the user to own a range of subordinate UIDs/GIDs listed
in `/etc/subuid` and `/etc/subgid`.

## The subuid trap

NixOS generates `/etc/subuid` and `/etc/subgid` exclusively from
`users.users.<name>.subUidRanges` / `subGidRanges`. The `hermes` account is
created by the upstream hermes-agent NixOS module, which declares no subid
ranges, so both files rendered empty and the per-user unit failed:

```
docker.service for the hermes user: No subuid ranges found for user 997 (hermes)
```

...after which it hit its start-limit and stayed down. Rootless enablement was
silently dead on arrival until machines declared the ranges itself.

## The fix

`modules/nixos/users/hermes.nix` — the module owning machines-side settings for
the `hermes` user — declares a 65536-wide range starting at 196608:

```nix
users.users.hermes = {
  subUidRanges = [ { startUid = 196608; count = 65536; } ];
  subGidRanges = [ { startGid = 196608; count = 65536; } ];
  extraGroups = [ "adm" "systemd-journal" ];
};
```

The module is imported by `mkAutomataContainerdisk` in
`modules/flake/nixos.nix` (and by the nixtar host), so the ranges land in the
containerdisk image. Verify on a booted guest with:

```
getent subuid hermes
systemctl --user -M hermes@ status docker
```

## References

- PR #1766 — Declare subid ranges for the hermes user on automata
