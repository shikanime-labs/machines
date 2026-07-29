# Ishtar Authentication Architecture

How authentication works on `ishtar` (Razer Blade 17, x86_64-linux NixOS), and
why Windows Hello is not applicable here.

## What's already in place

The auth stack is fprintd → pam_fprintd → Noctalia polkit agent → Bitwarden
"Unlock with system authentication".

| Layer                 | Module location                                                                                              | What it does                                                                                                                                                                                                         |
| --------------------- | ------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Fingerprint PAM stack | `modules/nixos/profiles/graphical.nix` → `services.fprintd.enable = true`                                    | Loads `pam_fprintd` into the auth path so a fingerprint can satisfy an `auth_self` polkit check.                                                                                                                     |
| polkit action         | `modules/nixos/profiles/graphical.nix` → `environment.etc."polkit-1/actions/com.bitwarden.Bitwarden.policy"` | Declares `com.bitwarden.Bitwarden.unlock` with `<allow_active>auth_self</allow_active>`, letting the active session user auth as themselves. Without this file the polkit agent rejects the Bitwarden unlock action. |
| App package           | `modules/nixos/profiles/graphical.nix` → `environment.systemPackages` adds `bitwarden-desktop`               | Installs the native Bitwarden desktop app.                                                                                                                                                                           |
| Launcher plugin       | `modules/home/graphical.nix` → `programs.noctalia.settings.plugins.enabled` includes `noctalia/bitwarden`    | Surfaces Bitwarden in the Noctalia launcher / shell.                                                                                                                                                                 |
| SSH agent socket      | `modules/nixos/users/shika.nix` → `home.sessionVariables`                                                    | Points `BITWARDEN_SSH_AUTH_SOCK` and `SSH_AUTH_SOCK` at `$XDG_RUNTIME_DIR/.bitwarden-ssh-agent.sock` so the socket lives under `/run/user/$UID` instead of `$HOME` root.                                             |
| Noctalia polkit agent | `modules/home/graphical.nix` → `programs.noctalia.settings.shell.polkit_agent = true`                        | In-session polkit agent that surfaces the fingerprint gate for Bitwarden unlock.                                                                                                                                     |

`security.polkit.enable` is on (in `graphical.nix`), as is
`gnome.gnome-keyring.enable` (for Thunderbird credentials).

## Why Windows Hello is not applicable

### Technical limitation

Windows Hello biometric authentication is built on **WinRT/BiometricFramework**
— a Windows-specific API surface. Linux has no equivalent:

- No `BiometricAuthentication` WinRT contract exists on Linux.
- WebAuthn/FIDO2 (available on Linux via `libfido2` + `pam_u2f`) handles
  **external hardware security keys**, not platform-bound biometrics.
- The closest Linux equivalent for platform biometrics is **fprintd**
  (`pam_fprintd`), which is already wired on ishtar.

### Hardware limitation

`howdy` provides Windows Hello-style facial authentication for Linux (IR-camera
based, MIT license). However:

- ishtar is a Razer Blade 17 — it has **no IR camera**.
- A standard webcam cannot serve as a Windows Hello substitute; the Windows
  Hello stack requires IR illumination + depth sensor fusion.

### Conclusion

There is no software package to install and no configuration to change to enable
"Windows Hello" on ishtar. The existing fprintd stack is the correct and
complete biometric auth solution for this hardware. If you want to add biometric
unlock for Bitwarden, the path is through `fprintd-enroll` — see
`docs/bitwarden-biometric.md`.

## Files in this chain

All NixOS-level config: `modules/nixos/profiles/graphical.nix` All home-manager
config: `modules/home/graphical.nix` User-specific overrides:
`modules/nixos/users/shika.nix` Bitwarden polkit policy:
`modules/nixos/profiles/graphical.nix` (inline in `environment.etc`) Host
config: `hosts/ishtar/configuration.nix`
