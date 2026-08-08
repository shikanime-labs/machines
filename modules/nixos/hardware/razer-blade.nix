{
  # UEFI laptop bootloader (Razer Blade 17, 2019). Windows dual-boot via systemd-boot.
  # Windows entry is automatically detected by systemd-boot.
  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot.enable = true;
  };

  # Razer Blade 17 peripherals: daemon + udev rules.
  hardware.openrazer = {
    enable = true;
    # The openrazer module creates an `openrazer` group whose members come ONLY
    # from this list; without it the daemon exits 1 ("User is not a member of
    # the openrazer group") and the user service hits start-limit-hit at boot.
    users = [ "shika" ];
  };

  # CPU/device power management + suspend-on-lid-close.
  powerManagement.enable = true;

  services = {
    fstrim.enable = true;
    udisks2.enable = true;
  };
}
