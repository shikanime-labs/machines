# Daily-driver desktop apps and session plumbing shared by every graphical host.
{
  pkgs,
  ...
}:

{
  environment = {
    # Niri's built-in default spawns `${env TERMINAL alacritty}` on Super+Enter.
    # Point it at Ghostty (provided by the home config) without a full config.kdl.
    sessionVariables.TERMINAL = "ghostty";

    systemPackages =
      with pkgs;
      let
        screenshot = [
          grim # capture
          slurp # region selection
          swappy # annotate/edit captures
        ];
        wayland = [
          xhost # lets gparted's root-launch wrapper grant root the Xwayland display
          xwayland-satellite # bridge x11 apps
        ];
      in
      [
        bitwarden-desktop # password manager
        brightnessctl # backlight/brightness keys under Niri
        ddcutil # DDC/CI external monitor brightness/control
        element-desktop # Matrix client
        fuzzel # app launcher; Niri's default config binds Super+R to it
        gparted-full # disk partition GUI (full FS tool set: resize/move any fs)
        nautilus # file manager GUI
        pavucontrol # audio mixer GUI (volume keys only step, no panel)
        playerctl # media-key control for MPRIS players
      ]
      ++ screenshot
      ++ wayland;
  };

  # Flatpak sandboxing. The module asserts xdg.portal.enable,
  # so the portal must be on or the build fails.
  services.flatpak.enable = true;

  xdg.portal.enable = true;
}
