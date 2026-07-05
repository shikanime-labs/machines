{
  imports = [
    ./rpi.nix
  ];

  hardware.raspberry-pi."4".fkms-3d.enable = true;

  # Disable UAS for external USB drives - use more stable usb-storage
  # Blacklist UAS kernel module to prevent crashes on VL805
  boot.blacklistedKernelModules = [ "uas" ];
}
