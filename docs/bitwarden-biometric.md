# Bitwarden Biometric (Fingerprint) Unlock on NixOS

How the fingerprint-unlock path for the Bitwarden desktop app is wired on
graphical NixOS hosts (currently `ishtar`), and how to enroll, use, and
troubleshoot it.

## What this enables

Bitwarden's desktop app can unlock with **system authentication** — a
fingerprint (via `fprintd`/`pam_fprintd`) or the account password, surfaced
through the in-session polkit agent (Noctalia) instead of Bitwarden's own master
password prompt. The SSH agent socket that Bitwarden exposes is also relocated
off `$HOME` into the XDG runtime dir.

Face recognition (`howdy`) is intentionally **not** wired — `ishtar` has no IR
camera.

## Config chain

All of this is declarative; once switched in, no per-host editing is needed.

| Layer                 | Where                                                                                                        | What it does                                                                                                                                                                                                         |
| --------------------- | ------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Fingerprint PAM stack | `modules/nixos/profiles/graphical.nix` → `services.fprintd.enable = true`                                    | Loads `pam_fprintd` into the auth path so a fingerprint can satisfy an `auth_self` polkit check.                                                                                                                     |
| polkit action         | `modules/nixos/profiles/graphical.nix` → `environment.etc."polkit-1/actions/com.bitwarden.Bitwarden.policy"` | Declares `com.bitwarden.Bitwarden.unlock` with `<allow_active>auth_self</allow_active>`, letting the active session user auth as themselves. Without this file the polkit agent rejects the Bitwarden unlock action. |
| App package           | `modules/nixos/profiles/graphical.nix` → `environment.systemPackages` adds `bitwarden-desktop`               | Installs the native Bitwarden desktop app.                                                                                                                                                                           |
| Launcher plugin       | `modules/home/graphical.nix` → `programs.noctalia.settings.plugins.enabled` includes `noctalia/bitwarden`    | Surfaces Bitwarden in the Noctalia launcher / shell.                                                                                                                                                                 |
| SSH agent socket      | `modules/nixos/users/shika.nix` → `home.sessionVariables`                                                    | Points `BITWARDEN_SSH_AUTH_SOCK` and `SSH_AUTH_SOCK` at `$XDG_RUNTIME_DIR/.bitwarden-ssh-agent.sock` so the socket lives under `/run/user/$UID` instead of `$HOME` root.                                             |

`security.polkit.enable` is already on for graphical hosts, as is the Noctalia
in-session polkit agent (`programs.noctalia.settings.shell.polkit_agent`).

Note: the polkit policy file is emitted as a Nix indented string with **no XML
prolog**. libxml2/polkit require the `<policyconfig>` declaration at byte 0, and
Nix indented strings keep the leading indent — so do not add a `<?xml … ?>` line
or the policy is silently dropped.

## Enrollment (one-time, per user)

The fingerprint must be enrolled into `fprintd` before it can satisfy any auth
check. Enroll **as the user who will unlock Bitwarden** (not root):

```sh
fprintd-enroll
```

- Follow the on-screen prompts; it captures multiple swipes of the same finger.
- To enroll a different finger later, re-run the command.
- The enrolled print is stored per-user in `fprintd`'s store and persists across
  rebuilds.

## Using biometric unlock

1. Open the Bitwarden desktop app.
2. Go to **Settings → Security** and enable **Unlock with system
   authentication**.
3. On the next unlock (or when an SSH key is requested through the agent), the
   Noctalia polkit agent surfaces a gate: scan your finger, or fall back to your
   account password.

The `noctalia/bitwarden` plugin additionally exposes Bitwarden actions from the
launcher.

## SSH agent

Bitwarden's SSH agent socket is advertised via `BITWARDEN_SSH_AUTH_SOCK`, and
`SSH_AUTH_SOCK` is pointed at the same path so normal `ssh`/`git` pick it up.
Both resolve to `$XDG_RUNTIME_DIR/.bitwarden-ssh-agent.sock` at runtime
(`$XDG_RUNTIME_DIR` is set by elogind/pam on login). Enable **SSH agent** in
Bitwarden's settings to populate keys.

## Troubleshooting

- **No fingerprint prompt at all / polkit rejects the unlock.** Confirm the
  policy file landed: `ls /etc/polkit-1/actions/com.bitwarden.Bitwarden.policy`.
  If absent after a switch, the build dropped it — most likely an XML prolog was
  added (see the note above) or the `graphical` profile wasn't applied to the
  host.
- **"No fingerprints enrolled" / fingerprint not recognized.** Run
  `fprintd-enroll` as your user and re-enroll. A dirty/mis-swiped enrollment
  fails silently at the gate — re-enroll the same finger.
- **Fingerprint works but password fallback is denied.** The `auth_self` default
  requires the _same_ user who enrolled to authenticate. Unlocking as a
  different session user won't satisfy `auth_self`.
- **SSH agent socket missing (`No such file or directory`).** Bitwarden's SSH
  agent only creates the socket when **SSH agent** is enabled in Bitwarden
  settings and the app is running/unlocked. `$XDG_RUNTIME_DIR` must be set (it
  is, under elogind). Verify with `echo $SSH_AUTH_SOCK` in the session.
- **Launcher shows no Bitwarden action.** Confirm `noctalia/bitwarden` is in
  `plugins.enabled` and the home config was switched in. Run
  `noctalia config validate` on the Linux host (the binary is Linux/Wayland
  only; it cannot run on macOS).
- **`fprintd-enroll` reports "No devices available".** The reader isn't claimed
  by the kernel — check `lsusb` / `fprintd-list` and that no other service owns
  the device. This is a hardware/driver concern, not a Nix build concern.
