{
  # Global Noctalia desktop shell theme for graphical Linux hosts.
  # NixOS-level programs.noctalia has no `settings`; theming is home-manager only,
  # so this is the shared home module all graphical users import.
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      backdrop = {
        enabled = true;
        blur_intensity = 0.5; # default; 0.0 = no blur, 1.0 = max
        tint_intensity = 0.3; # 0.0 = no tint, 1.0 = opaque
      };
      calendar.enabled = true;
      location.auto_locate = true;
      # Load the Bitwarden vault-lookup plugin from this repo (path source).
      # Location points at the official source dir, so the plugin id
      # "shikanime/bitwarden" resolves to plugins/official/bitwarden/plugin.toml.
      # (noctalia/translator is an upstream-official plugin: auto-seeded source,
      # so it needs no source declaration.)
      plugins = {
        sources = [
          {
            kind = "path";
            name = "machines-local";
            location = "plugins/official";
            enabled = true;
          }
        ];
        enabled = [
          "shikanime/bitwarden"
          "noctalia/translator"
        ];
      };
      shell = {
        font = "Fira Code";
        polkit_agent = true;
        greeter_sync.auto_sync = true;
      };
      theme = {
        mode = "auto";
        source = "builtin";
        builtin = "Catppuccin";
      };
    };
  };

  xdg.configFile."niri/config.kdl".text = ''
    // Niri settings for Noctalia integration (Noctalia v5 Niri compositor spec).
    // §1 spawn-at-startup omitted: Noctalia already auto-starts via systemd user service.

    window-rule {
        geometry-corner-radius 20
        clip-to-geometry true
    }

    window-rule {
        match app-id="dev.noctalia.Noctalia"
        open-floating true
        default-column-width { fixed 1080; }
        default-window-height { fixed 920; }
    }

    debug {
        // Required, or Noctalia notification actions / window activation won't work.
        honor-xdg-activation-with-invalid-serial
    }

    binds {
        Mod+Space { spawn-sh "noctalia msg panel-toggle launcher"; }
        Mod+S { spawn-sh "noctalia msg panel-toggle control-center"; }
        Mod+Comma { spawn-sh "noctalia msg settings-toggle"; }
        Alt+Tab { spawn-sh "noctalia msg window-switcher"; }

        XF86AudioRaiseVolume { spawn-sh "noctalia msg volume-up"; }
        XF86AudioLowerVolume { spawn-sh "noctalia msg volume-down"; }
        XF86AudioMute { spawn-sh "noctalia msg volume-mute"; }
        XF86MonBrightnessUp { spawn-sh "noctalia msg brightness-up"; }
        XF86MonBrightnessDown { spawn-sh "noctalia msg brightness-down"; }
    }

    // Laptop: lock + suspend on lid close (ishtar). logind HandleLidSwitch=ignore
    // set at the NixOS level so systemd doesn't also suspend.
    switch-events {
        lid-close { spawn "noctalia" "msg" "session" "lock-and-suspend"; }
    }
  '';
}
