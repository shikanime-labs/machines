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
    # BCM2712 external PCIe root (bus 0001) quirk: ASPM L1 wedges the NVMe admin
    # queue on Samsung PM9B1-class drives (probe timeout). `=off` stops Linux from
    # managing ASPM. Verified 2026-08-02: enumerates, XFS mounts, 0 smart errors.
    "pcie_aspm=off"
  ];
}
