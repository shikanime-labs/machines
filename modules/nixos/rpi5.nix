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
}
