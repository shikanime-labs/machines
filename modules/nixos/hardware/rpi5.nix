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

  boot.kernelParams = [
    # Probe -12 ENOMEM: 64 MiB default CMA too small for NVMe admin queue / PRP DMA.
    "cma=512M"
    # Probe -4 EINTR (admin queue timeout) on Samsung PM9B1 behind RP1 pcie:
    # ASPM L1 wedges the link at init. `=off` fully disables L1.x; `policy=performance`
    # still allows L1 entry and did not fix it. Verified 2026-08-02: enumerates,
    # XFS mounts, 0 smart errors. Prior generations in extlinux if it regresses.
    "pcie_aspm=off"
    "nvme_core.default_ps_max_latency_us=0"
  ];
}
