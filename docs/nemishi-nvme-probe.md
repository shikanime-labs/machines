# nemishi NVMe Probe Timeout — Root Cause & Fix

## Symptom

`nemishi` (RPi 5, aarch64) boots off SD (`mmcblk0`) but `systemd` blocks on the
declared `disko` device:

```text
systemd[1]: Timed out waiting for device /dev/nvme0n1.
```

`/dev/nvme*` never appears. Looks like a dead drive. It isn't.

## Root Cause

The Samsung PM9B1 (DRAM-less) enumerates fine on the Pi 5 PCIe root
(`0001:01:00.0` in `lspci`), but the `nvme` driver probe fails:

```text
nvme nvme0: I/O tag 20 QID 0 timeout, disable controller
nvme nvme0: Identify Controller failed (-4)
nvme 0001:01:00.0: probe with driver nvme failed with error -5
```

`QID 0` is the admin queue; `Identify` is the first command the driver sends. It
times out → controller disabled → no block device. Two host-side causes:

1. **APST** (Autonomous Power State Transition): PM9B1 drops to low-power faster
   than it can wake the admin queue for `Identify` → timeout.
2. **PCIe ASPM L1**: BCM2712 root defaults L1 on; link sleep wedges the admin
   queue (the `-12`/ENOMEM class failure).

`rpi5.nix` documented both fixes but only applied `cma=512M` — the disables were
never added to `boot.kernelParams`.

## Fix

`modules/nixos/rpi5.nix`:

```nix
boot.kernelParams = [
  # Probe error -12 (ENOMEM): default 64 MiB CMA too small for NVMe admin
  # queue / PRP DMA. Without cma=512M the probe fails even with the overlay.
  "cma=512M"
  # Samsung PM9B1 probe failure on Pi 5 root port:
  #  1. APST wake timeout on admin-queue Identify  -> disable APST
  #  2. PCIe ASPM L1 on BCM2712 root               -> force L1 off
  "nvme_core.default_ps_max_latency_us=0"   # disables APST
  "pcie_aspm.policy=performance"             # forces L1 off
];
```

`cma=512M` and the `pcie-32bit-dma-pi5` overlay (32-bit DMA mask for the root)
are unchanged and required.

## Live Verification (no rebuild)

```text
echo 0 > /sys/module/nvme_core/parameters/default_ps_max_latency_us
echo performance > /sys/module/pcie_aspm/parameters/policy
echo 1 > /sys/bus/pci/devices/0001:01:00.0/remove
echo 1 > /sys/bus/pci/devices/0001:00:00.0/rescan
# -> /dev/nvme0n1 appears, XFS mounts at /mnt/data, smartctl -H PASSED
```

First failed probe wedges the controller; `remove`+`rescan` re-probes clean with
APST off. sysfs edits do not survive reboot — rebuild + reboot to persist.

## Recovery

If NVMe is missing after boot:

```text
nvme list                       # empty / no /dev/nvme0n1
echo 0 > /sys/module/nvme_core/parameters/default_ps_max_latency_us
echo performance > /sys/module/pcie_aspm/parameters/policy
echo 1 > /sys/bus/pci/devices/0001:01:00.0/remove
echo 1 > /sys/bus/pci/devices/0001:00:00.0/rescan
ls -la /dev/nvme0n1
```
