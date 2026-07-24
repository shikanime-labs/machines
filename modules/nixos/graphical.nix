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

  # Gaming + laptop utilities
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

  # XWayland for the rare X11 app under Niri. Keep xserver on for the XWayland socket.
  services.xserver.enable = true;

  # Niri compositor (ships wayland-sessions/niri.desktop; the greeter lists it).
  programs.niri.enable = true;

  # Noctalia shell/bar as a systemd user service (auto-starts in the Wayland session).
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
  };

  # Noctalia Greeter as the greetd login UI.
  programs.noctalia-greeter = {
    enable = true;
    settings = {
      cursor = {
        theme = "Adwaita";
        size = 24;
      };
      keyboard = {
        layout = "us";
      };
      theme = {
        mode = "dark";
      };
    };
  };

  # greetd daemon. `default_session.user` defaults to "greeter" (auto-created by the module).
  # The Noctalia Greeter module sets default_session.command to its session binary.
  services.greetd.enable = true;
}
