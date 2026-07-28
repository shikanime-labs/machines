# Stopping the raspberrypi-firmware spam on nemishi

## What the message is
`raspberrypi-firmware soc@...: Request 0x0003xxxx returned status 0x00000000`
is emitted by `drivers/firmware/raspberrypi.c` at the `dev_err` path
(lines 118-126, current mainline). The mailbox transaction succeeded (no
timeout) but the VPU returned `RPI_FIRMWARE_STATUS_REQUEST` (0x00000000)
instead of `RPI_FIRMWARE_STATUS_SUCCESS` (0x80000000); the kernel returns
`-EINVAL` and logs it. It is a kernel<->VPU clock-ID mismatch on the Pi 5
(bcm2712), recurring ~9.5 msg/s in a SET/GET clock-rate poll loop.
Benign: no crash, no timeout, no data loss; the clock still works.

## Why `consoleLogLevel=4` does NOT fix it
The message is `dev_err` -> **KERN_ERR (priority 3)**. The kernel only
echoes a message to the console when `priority < console_loglevel`.
`consoleLogLevel=4` sets the console threshold to 4, so priority-3 ERR is
still printed. `consoleLogLevel=4` is *already set* in
`modules/nixos/hardware/rpi.nix:17` and the spam continues -- so that knob
cannot silence this line. (That was the prior recommendation in
t_89d70263; it is ineffective for this exact message.)

## Why there is no clean userspace mute
- `loglevel=3` (consoleLogLevel=3) WOULD stop the console/serial echo
  (3 < 3 is false). But it also hides *every* ERR-level console message,
  and it does NOT remove the lines from the ring buffer -- they still
  appear in `dmesg` / `journalctl -k -f` (the format pasted is ring-buffer
  output). On nemishi, serial-console ERR visibility is part of the
  operator's recovery discipline, so silencing all ERR is risky.
- journald has no per-message kernel drop; `MaxLevelStore` is global and
  would also discard real errors.
- A kernel patch to downgrade this one `dev_err` to `dev_dbg` is
  out-of-scope for this repo and contradicts the "no firmware/kernel
  change without fallback media" rule for nemishi.

## Options
1. Leave it. Benign noise; operation unaffected. (Recommended unless the
   volume causes a real problem.)
2. Pursue the root cause: align the kernel/firmware clock-ID handling on
   Pi 5 (kernel or `hardware.raspberry-pi.firmware` version bump). This is
   the only change that actually removes the message -- but it is a
   firmware/kernel change on a safety-critical host and needs the
   operator's fallback-media sign-off first.

## Decision needed
Which option? If (2), a follow-up task will bump the kernel/firmware pin on
nemishi behind the usual recovery gates.
