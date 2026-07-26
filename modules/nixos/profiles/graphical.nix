{ pkgs, ... }:

{
  imports = [
    ./machine.nix
    ./workstation.nix
  ];

  environment = {
    # Niri's built-in default spawns `${env TERMINAL alacritty}` on Super+Enter.
    # Point it at Ghostty (provided by the home config) without a full config.kdl.
    sessionVariables.TERMINAL = "ghostty";

    # Gaming + laptop utilities the graphical session needs at the system level.
    systemPackages =
      with pkgs;
      let
        # Wayland session utilities: launcher + media/backlight controls that must
        # resolve on Niri's spawned PATH (compositor launches them directly).
        laptopSessionUtils = [
          brightnessctl # backlight/brightness keys under Niri
          fuzzel # app launcher; Niri's default config binds Super+R to it
          gparted-full # disk partition GUI (full FS tool set: resize/move any fs)
          pavucontrol # audio mixer GUI (volume keys only step, no panel)
          playerctl # media-key control for MPRIS players
        ];
      in
      laptopSessionUtils;
  };

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
      recommendedServices.enable = true;
      systemd.enable = true;
    };

    noctalia-greeter.enable = true;

    # Niri forces XWayland off (the wayland-session import passes enableXWayland=false).
    # Re-enable it so X11 apps actually start under Niri.
    xwayland.enable = true;
  };

  # greetd daemon. `default_session.user` defaults to "greeter" (auto-created by the module).
  # The Noctalia Greeter module sets default_session.command to its session binary.
  services = {
    # Flatpak sandboxing for graphical hosts. The module asserts xdg.portal.enable,
    # so the portal must be on or the build fails.
    flatpak.enable = true;

    greetd.enable = true;

    # Secret Service daemon so Thunderbird's login manager stores credentials
    # encrypted (Niri ships no keyring today).
    gnome.gnome-keyring.enable = true;

    # XWayland for the rare X11 app under Niri. Keep xserver on for the XWayland socket.
    xserver.enable = true;
  };

  xdg.portal.enable = true;

  # polkit authority daemon: required for the privilege prompts that
  # pkexec/gparted raise. Noctalia's built-in in-session agent (enabled via
  # programs.noctalia.settings.shell.polkit_agent in the home module) registers
  # against this daemon, so the external polkit-gnome agent is intentionally
  # omitted to avoid two agents racing for the session-bus registration.
  security.polkit.enable = true;
}
