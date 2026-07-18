{
  imports = [
    ./rpi.nix
  ];

  # Install the firmware specifically for the Raspberry Pi 5
  # because the nixpkgs doesn't provide it by default anymore
  # up to Raspberry Pi 4
  hardware.raspberry-pi.firmware = {
    enable = true;
    uboot.enable = true;
  };

  # Samsung PM9B1 NVMe (PCIe x1) fails to probe on the Pi 5 root port.
  # Two issues, confirmed live:
  #   1. APST power-state entry can't be woken in time for the admin-queue Identify
  #      -> nvme nvme0: I/O tag 24 QID 0 timeout, disable controller
  #   2. PCIe ASPM L1 on the BCM2712 root (default policy) -> probe error -12
  # Both must be disabled for a clean probe.
  boot.kernelParams = [
    "nvme_core.default_ps_max_latency_us=0"
    "pcie_aspm=off"
  ];
}
