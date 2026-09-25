# Session entry: greetd + Noctalia greeter, Niri, Noctalia shell, comin desktop
# agent, and the logind lid policy Niri's switch-events rule depends on.
{
  programs = {
    # Niri compositor (ships wayland-sessions/niri.desktop; the greeter lists it).
    niri.enable = true;

    # Noctalia shell/bar as a systemd user service (auto-starts in the Wayland session).
    noctalia = {
      enable = true;
      recommendedServices.enable = true;
      systemd.enable = true;
    };

    noctalia-greeter = {
      enable = true;
      # Colemak at the login screen: XKB "us" layout + "colemak" variant,
      # written to greeter.toml's [keyboard] section (greeter-scoped, not system-wide).
      settings.keyboard = {
        layout = "us";
        variant = "colemak";
      };
    };
  };

  # greetd daemon. `default_session.user` defaults to "greeter" (auto-created by
  # the module). The Noctalia Greeter module sets default_session.command to its
  # session binary.
  services = {
    greetd.enable = true;

    # Comin declarative remote deployment — enables the systemd user service
    # that applies NixOS configurations from a remote builder.
    comin.desktop.enable = true;

    # Let niri own the lid-close action (lock-and-suspend) instead of logind's
    # default suspend, which would race with niri's switch-events rule.
    logind.settings.Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchDocked = "ignore";
    };

    # XWayland for the rare X11 app under Niri. Keep xserver on for the XWayland socket.
    # videoDrivers = [ "nvidia" ] is supplied by nixos-hardware's common-gpu-nvidia.
    xserver.enable = true;
  };
}
