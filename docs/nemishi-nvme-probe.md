# nemishi NVMe Probe Timeout — Root Cause & Fix

## Symptom

`nemishi` (RPi 5, aarch64) boots off SD (`mmcblk0`) but `systemd` blocks on the
declared `disko` device:

```text
systemd[1]: Timed out waiting for device /dev/nvme0n1.
```

`/dev/nvme*` never appears. Looks like a dead drive. It wasn't.

## Root Cause (the real one)

The M.2 HAT+ 16-pin FPC ribbon to the Pi's board connector was not seated. That
ribbon carries 5V to the HAT — without it the SSD gets no power. The NVMe
_controller_ still enumerates on PCIe (`/dev/nvme0` exists) but reports **0
bytes** (`/sys/block/nvme0n1/size == 0`), so the kernel can't mount or probe it
and you get `No such device` / `XFS SB validate failed`.

Seat the 16-pin ribbon, power-cycle, `cat /sys/block/nvme0n1/size` should
be > 0.

## Secondary tuning (Pi 5 host side, not the cause)

`rpi5.nix` keeps one host-side insurance setting:

- **PCIe ASPM L1**: the BCM2712 external PCIe root (bus `0001`) defaults L1 on;
  on Samsung PM9B1-class drives L1 wedges the NVMe admin queue at init, a
  separate `probe timeout` trap from the power-ribbon issue. `rpi5.nix` sets
  `pcie_aspm=off` (stops Linux managing ASPM) as one-line insurance against it.

The following were evaluated during the upstream nixos-hardware#1953 thread and
**removed** from `rpi5.nix`:

- `cma=512M` — Pi 5 DTB already reserves 64 MiB CMA; the drive's 64 MiB HMB
  request is capped at 32 MiB (satisfies its minimum) and allocated outside CMA,
  with HMB failure nonfatal. Not required.
- `pcie-32bit-dma-pi5` overlay — changes DMA addressing and MSI routing; not
  enabled globally without further investigation.
- `nvme_core.default_ps_max_latency_us=0` (APST) — applied after the first
  Identify command, so it cannot fix an initial Identify timeout.

Restore any of the above only if you re-test in isolation and confirm it is
required on this hardware.

## Live Verification (post-reseat, no rebuild)

```text
cat /sys/block/nvme0n1/size        # > 0 once the ribbon is seated
ls -la /dev/nvme0n1                 # block device present
# XFS mounts at /mnt/data, smartctl -H PASSED
```

## History

An earlier version of this doc blamed APST + ASPM for a "timeout, disable
controller" probe failure and carried `cma=512M` + the `pcie-32bit-dma-pi5`
overlay as required. The timeout log was from a _separate_ pre-power-ribbon
state; the 0-byte / `No such device` symptom the host actually hit was pure
missing 5V. After the upstream review, `rpi5.nix` carries only `pcie_aspm=off`.
