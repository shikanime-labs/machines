{ pkgs, ... }:

{
  # UEFI laptop bootloader (Razer Blade 17, 2019). Windows dual-boot via systemd-boot.
  # Windows entry is automatically detected by systemd-boot.
  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot.enable = true;
  };

  # Razer Blade 17 peripherals: daemon + udev rules.
  hardware.openrazer.enable = true;

  # CPU/device power management + suspend-on-lid-close.
  powerManagement.enable = true;

  # NVIDIA GeForce RTX (Max-Q) dGPU — Razer Blade 17 specific.
  hardware.nvidia = {
    open = false; # proprietary/closed kernel module, per explicit request
    modesetting.enable = true;
    powerManagement = {
      enable = true;
      # Fine-grained RTD3: per-frame power-state transitions instead of a coarse
      # on/off switch. Valid because prime.offload.enable is set (assertion:
      # finegrained -> offload).
      finegrained = true;
    };
    prime.offload = {
      enable = true;
      enableOffloadCmd = true; # provides `nvidia-offload` wrapper
    };
  };

  # NVDEC hardware video decode (browser/media players) on the dGPU.
  hardware.graphics.extraPackages = with pkgs; [ nvidia-vaapi-driver ];

  services = {
    fstrim.enable = true;
    udisks2.enable = true;
  };
}
