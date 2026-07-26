{ pkgs, ... }:

{
  imports = [
    ./machine.nix
    ./workstation.nix
  ];

  # Gaming + laptop utilities
  environment.systemPackages = with pkgs; [
    brightnessctl
    fuzzel # App launcher; niri's default config binds Super+R to it.
    pavucontrol
    playerctl
    wine
    wine64
    winetricks
    protonup-qt
    bottles
    heroic
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

  programs = {
    # Niri compositor (ships wayland-sessions/niri.desktop; the greeter lists it).
    niri.enable = true;

    # Noctalia shell/bar as a systemd user service (auto-starts in the Wayland session).
    noctalia = {
      enable = true;
      systemd.enable = true;
    };

    noctalia-greeter = {
      enable = true;
      settings = {
        cursor = {
          theme = "Adwaita";
          size = 24;
        };
        theme = {
          mode = "dark";
        };
      };
    };

    # Thunderbird mail client on the managed Ishtar workstation.
    # Native IMAP/CardDAV/CalDAV does the sync; this module only configures it
    # and force-installs the locked Ishtar MailExtension.
    thunderbird.enable = true;

    steam.enable = true;
  };

  # greetd daemon. `default_session.user` defaults to "greeter" (auto-created by the module).
  # The Noctalia Greeter module sets default_session.command to its session binary.
  services = {
    greetd.enable = true;

    # Secret Service daemon so Thunderbird's login manager stores credentials
    # encrypted (Niri ships no keyring today).
    gnome.gnome-keyring.enable = true;

    # XWayland for the rare X11 app under Niri. Keep xserver on for the XWayland socket.
    xserver.enable = true;
  };

  # Niri's built-in default spawns `${env TERMINAL alacritty}` on Super+Enter.
  # Point it at Ghostty (provided by the home config) without a full config.kdl.
  environment.sessionVariables.TERMINAL = "ghostty";
}
