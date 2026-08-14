{ config, pkgs, ... }:

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
        element-desktop # Matrix client
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

    noctalia-greeter = {
      enable = true;
      # Colemak at the login screen: XKB "us" layout + "colemak" variant,
      # written to greeter.toml's [keyboard] section (greeter-scoped, not system-wide).
      settings.keyboard = {
        layout = "us";
        variant = "colemak";
      };
    };

    # OBS Studio — video recording and live streaming with recommended plugins
    # and virtual camera support (for Zoom/Teams). Hardware-accelerated on NVIDIA.
    obs-studio = {
      enable = true;
      enableVirtualCamera = true;
      plugins = with pkgs.obs-studio-plugins; [
        obs-vkcapture # Vulkan/OpenGL game capture
        advanced-scene-switcher # automated scene switching
        input-overlay # show keyboard/gamepad input on stream
        obs-composite-blur # blur filter with proper compositing
        obs-backgroundremoval # background removal filter
        obs-gstreamer # GStreamer source/encoder/filter
      ];
    };

    # GameMode: daemon that applies on-demand optimizations while a game holds
    # a request (CPU governor -> performance, process renice). Trigger per-game
    # with the `gamemoderun` wrapper in the launch options (e.g. `gamemoderun %command%`).
    # enableRenice defaults true, giving gamemoded CAP_SYS_NICE so it can renice.
    gamemode = {
      enable = true;
      settings = {
        general.renice = 10; # nice the game process while GameMode is active
        # Optional NVIDIA side: pin the dGPU to fixed-performance so it doesn't
        # clock-drop under load (fps for heat). Best-effort under Wayland — the
        # NV-CONTROL write can no-op if there's no X display; harmless if so.
        # Drop this `custom` block to keep the adaptive PowerMizer default.
        custom = {
          # Resolves to the nvidia-settings store path (the nvidia package exposes
          # it as `config.hardware.nvidia.package.settings`). Pin the dGPU to
          # fixed-performance so it doesn't clock-drop under load (fps for heat).
          # Best-effort under Wayland — the NV-CONTROL write can no-op without an
          # X display; harmless. Drop this block to keep adaptive PowerMizer.
          start = "${config.hardware.nvidia.package.settings}/bin/nvidia-settings -a [gpu:0]/GPUPowerMizerMode=1";
          end = "${config.hardware.nvidia.package.settings}/bin/nvidia-settings -a [gpu:0]/GPUPowerMizerMode=0";
        };
      };
    };

    # GameScope standalone binary with CAP_SYS_NICE so it can renice / go RT itself.
    # Your steam `gamescopeSession` already wraps Steam in gamescope; this makes the
    # bare `gamescope` command also cap_sys_nice-capable. Needs prime-offload (on).
    gamescope = {
      enable = true;
      capSysNice = true;
    };

    steam = {
      enable = true;
      localNetworkGameTransfers.openFirewall = true;
      protontricks.enable = true;
      remotePlay.openFirewall = true;
      # Make the Steam client itself enumerate the discrete NVIDIA GPU. On
      # prime-offload this laptop defaults Steam's client to the Intel iGPU (and
      # occasionally to the open-source NVK Mesa driver), so Steam's hardware
      # report shows "no NVIDIA card". The gamescope session wrapper below injects
      # the prime-offload env + NVIDIA-only Vulkan layer (the canonical set from
      # https://wiki.nixos.org/wiki/Nvidia: __NV_PRIME_RENDER_OFFLOAD=1,
      # __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0, __VK_LAYER_NV_optimus=NVIDIA_only),
      # which makes the proprietary driver the one Steam enumerates.
      gamescopeSession = {
        enable = true;
        env = {
          __NV_PRIME_RENDER_OFFLOAD = "1";
          __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
          __VK_LAYER_NV_optimus = "NVIDIA_only";
        };
      };
    };
  };

  # greetd daemon. `default_session.user` defaults to "greeter" (auto-created by the module).
  # The Noctalia Greeter module sets default_session.command to its session binary.
  services = {
    # Comin declarative remote deployment — enables the systemd user service
    # that applies NixOS configurations from a remote builder.
    comin.desktop.enable = true;

    # GNOME desktop session — selectable at the greetd greeter
    # as an alternative to Niri. The .desktop file lands in
    # wayland-sessions and noctalia-greeter picks it up.
    desktopManager.gnome.enable = true;

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
    # videoDrivers = [ "nvidia" ] is supplied by nixos-hardware's common-gpu-nvidia.
    xserver.enable = true;

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

  # Expose LM Studio over Tailscale HTTPS (ts.net endpoint on :1234). Runs after
  # tailscaled is up; `serve` persists in tailscaled state after first apply.
  systemd.services.tailscale-serve-lmstudio = {
    description = "Expose LM Studio over Tailscale serve";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "5s";
    };
    script = ''
      ${pkgs.tailscale}/bin/tailscale serve --yes --bg --https=1234 http://127.0.0.1:1234
    '';
  };
}
