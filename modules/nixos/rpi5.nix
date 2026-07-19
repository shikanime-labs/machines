{ pkgs, ... }:

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
    # Probe error -12 (ENOMEM) is also hit when the default 64 MiB CMA pool is too
    # small for the NVMe admin queue / PRP DMA buffers. Bump it so the driver can
    # allocate. Confirmed: without cma=512M the probe fails even with the overlay.
    "cma=512M"
    # PCIe ASPM L1 on the BCM2712 root port (default policy) -> probe error -12.
    # Force L1 off for a clean NVMe probe. (The earlier 0-byte / "missing device"
    # failure was the M.2 HAT 16-pin power ribbon, not APST — removed.)
    "pcie_aspm.policy=performance"
  ];

  hardware.deviceTree.overlays = [
    {
      name = "pcie-32bit-dma-pi5";
      dtboFile = "${pkgs.raspberrypifw}/share/raspberrypi/boot/overlays/pcie-32bit-dma-pi5.dtbo";
    }
  ];
}
