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
  ];
}
