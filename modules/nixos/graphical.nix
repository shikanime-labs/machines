{ pkgs, ... }:

{
  imports = [
    ./machine.nix
    ./workstation.nix
  ];

  hardware = {
    # WiFi / Bluetooth firmware for the laptop radios.
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      enable32Bit = true; # Gaming: 32-bit for Wine/Proton
    };
    bluetooth.enable = true;
    nvidia = {
      open = true;
      modesetting.enable = true;
      powerManagement.enable = true;
    };
  };

  programs.steam.enable = true;

  # Gaming + laptop utilities. Hyprland ecosystem is configured via home-manager programs.*.
  environment.systemPackages = with pkgs; [
    brightnessctl
    pavucontrol
    playerctl
    wine
    wine64
    winetricks
    protonup-qt
    bottles
    heroic
  ];

  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
  };

  # GDM (Wayland-only since GNOME 50) as the display manager. It auto-discovers
  # the Hyprland session via programs.hyprland.enable -> sessionPackages (withUWSM).
  services.displayManager.gdm.enable = true;

  # NixOS-level hyprland provides the desktop session; per-user config lives in home-manager.
  programs = {
    hyprland = {
      enable = true;
      withUWSM = true;
    };
    hyprlock.enable = true;
  };

  # NVIDIA + Hyprland (wlroots): avoid invisible/garbled hardware cursors.
  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";
}
