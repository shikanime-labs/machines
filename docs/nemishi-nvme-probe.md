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

DRM-less SSDs on the BCM2712 root can also wedge on admin-queue `Identify`:

- **PCIe ASPM L1**: root defaults L1 on; link sleep wedges the queue (`-12`
  class). `rpi5.nix` forces `pcie_aspm.policy=performance` (L1 off).
- **APST** was previously also disabled (`default_ps_max_latency_us=0`) but is
  **no longer needed** — removed once the real cause (power ribbon) was found.

`cma=512M` and the `pcie-32bit-dma-pi5` overlay remain required.

## Live Verification (post-reseat, no rebuild)

```text
cat /sys/block/nvme0n1/size        # > 0 once the ribbon is seated
ls -la /dev/nvme0n1                 # block device present
# XFS mounts at /mnt/data, smartctl -H PASSED
```

## History

Earlier this doc blamed APST + ASPM for a "timeout, disable controller" probe
failure. That log was from a _separate_ pre-power-ribbon state; the 0-byte /
`No such device` symptom the host actually hit was pure missing 5V. The
`nvme_core.default_ps_max_latency_us=0` workaround was stripped from `rpi5.nix`.

`pcie_aspm.policy=performance` was reviewed for removal but **kept**: it guards
a separate, real BCM2712 root-port quirk (ASPM L1 wedges the NVMe admin queue,
probe `-12`). The power-ribbon fix was _our_ failure; this is a different
hardware trap worth the one-line insurance.
