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
        fuzzel # app launcher; Niri's default config binds Super+R to it
        gparted-full # disk partition GUI (full FS tool set: resize/move any fs)
        nautilus # file manager GUI
        pavucontrol # audio mixer GUI (volume keys only step, no panel)
        playerctl # media-key control for MPRIS players
      ]
      ++ screenshot
      ++ wayland;

    # Host polkit policy for Bitwarden's "Unlock with system authentication".
    # Required so the in-session polkit agent (Noctalia) can surface the
    # fingerprint/password gate for the native Bitwarden app.
    # No XML prolog: Nix indented strings keep the leading indent, and a
    # polkit/libxml2 declaration must sit at byte 0 or the policy is dropped.
    etc."polkit-1/actions/com.bitwarden.Bitwarden.policy".text = ''
      <policyconfig>
          <action id="com.bitwarden.Bitwarden.unlock">
              <description>Unlock Bitwarden</description>
              <message>Authenticate to unlock Bitwarden</message>
              <defaults>
                  <allow_any>no</allow_any>
                  <allow_inactive>no</allow_inactive>
                  <allow_active>auth_self</allow_active>
              </defaults>
          </action>
      </policyconfig>
    '';
  };

  hardware = {
    # WiFi / Bluetooth firmware for the laptop radios.
    enableRedistributableFirmware = true;

    # Steam Input / Steam Controller udev rules (Valve's 60-steam-input.rules +
    # 60-steam-vr.rules) so gamepads grant the seated user uaccess without root.
    steam-hardware.enable = true;

    graphics = {
      enable = true;
      enable32Bit = true; # Gaming: 32-bit for Wine/Proton
    };
    bluetooth.enable = true;
    nvidia = {
      open = false; # proprietary/closed kernel module, per explicit request
      modesetting.enable = true;
      powerManagement.enable = true;
      prime.offload = {
        enable = true;
        enableOffloadCmd = true; # provides `nvidia-offload` wrapper
      };
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

    steam = {
      enable = true;
      localNetworkGameTransfers.openFirewall = true;
      gamescopeSession.enable = true;
      protontricks.enable = true;
      remotePlay.openFirewall = true;
    };
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
    gnome = {
      gnome-keyring.enable = true;
      gnome-online-accounts.enable = true;
      gnome-software.enable = true;
      sushi.enable = true;
    };

    # GVfs: trash, removable-media mount, and network shares for nautilus.
    gvfs.enable = true;

    # Let niri own the lid-close action (lock-and-suspend) instead of logind's
    # default suspend, which would race with niri's switch-events rule.
    logind.settings.Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchDocked = "ignore";
    };

    # XWayland for the rare X11 app under Niri. Keep xserver on for the XWayland socket.
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
    };

    # Fingerprint reader stack. Wires pam_fprintd into the auth path so the
    # polkit agent (Noctalia) can surface a fingerprint gate for Bitwarden's
    # "Unlock with system authentication". Enroll with `fprintd-enroll` as the user.
    fprintd.enable = true;
  };

  xdg.portal.enable = true;

  # polkit authority daemon: required for the privilege prompts that
  # pkexec/gparted raise. Noctalia's built-in in-session agent (enabled via
  # programs.noctalia.settings.shell.polkit_agent in the home module) registers
  # against this daemon, so the external polkit-gnome agent is intentionally
  # omitted to avoid two agents racing for the session-bus registration.
  security.polkit.enable = true;
}
