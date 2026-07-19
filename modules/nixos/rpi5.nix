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
    # Samsung PM9B1 NVMe (PCIe x1) fails to probe on the Pi 5 root port.
    # Two issues, confirmed live on nemishi:
    #   1. APST power-state entry can't be woken in time for the admin-queue Identify
    #      -> nvme nvme0: I/O tag 24 QID 0 timeout, disable controller
    #   2. PCIe ASPM L1 on the BCM2712 root (default policy) -> probe error -12
    # Both must be disabled for a clean probe. Applied below:
    #   - nvme_core.default_ps_max_latency_us=0  disables APST
    #   - pcie_aspm.policy=performance           forces L1 off
    "nvme_core.default_ps_max_latency_us=0"
    "pcie_aspm.policy=performance"
  ];

  hardware.deviceTree.overlays = [
    {
      name = "pcie-32bit-dma-pi5";
      dtboFile = "${pkgs.raspberrypifw}/share/raspberrypi/boot/overlays/pcie-32bit-dma-pi5.dtbo";
    }
  ];
}
