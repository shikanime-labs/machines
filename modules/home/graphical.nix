{ lib, pkgs, ... }:

{
  # Vicinae replaces the Noctalia launcher, panels, clipboard history,
  # emoji picker, and calculator.
  programs.vicinae = {
    enable = true;
    systemd.enable = true;
    settings.launcher_window.blur = true;
  };

  catppuccin = {
    waybar.enable = true;
    mako.enable = true;
    vicinae.enable = true;
    hyprlock.enable = true;
  };

  # Waybar replaces the Noctalia bar.
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      targets = [ "graphical-session.target" ];
    };
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 34;
      margin = "8 12 0 12";
      modules-left = [
        "niri/workspaces"
        "niri/window"
      ];
      modules-right = [
        "tray"
        "pulseaudio"
        "backlight"
        "battery"
        "clock"
      ];
      "niri/workspaces" = {
        format = "{index}";
      };
      "niri/window" = {
        format = "{}";
        max-length = 60;
      };
      pulseaudio = {
        format = "{volume}% {icon}";
        format-muted = "muted";
        format-icons.default = [
          "low"
          "mid"
          "high"
        ];
      };
      backlight = {
        device = "intel_backlight";
        format = "{percent}% sun";
      };
      battery = {
        states = {
          critical = 15;
          warning = 30;
        };
        format = "{capacity}% bat";
        format-charging = "{capacity}%chg";
      };
      clock = {
        format = "{:%H:%M}";
        format-alt = "{:%a %d %b %H:%M}";
      };
      tray = {
        icon-size = 18;
        spacing = 4;
      };
    };
  };

  # Mako replaces Noctalia notifications.
  services.mako = {
    enable = true;
    settings = {
      border-radius = 12;
      border-size = 2;
      default-timeout = 5000;
      layer = "top";
      width = 400;
      height = 200;
    };
  };

  # Mako's HM module ships no systemd integration; run it as a session service.
  systemd.user.services.mako = {
    Unit = {
      Description = "mako notification daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${lib.getExe pkgs.mako}";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Hyprlock + hypridle replace the Noctalia session bits.
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        grace = 5;
        hide_cursor = true;
      };
      background = [
        {
          path = "screenshot";
          blur_passes = 2;
          blur_size = 8;
        }
      ];
      input-field = [
        {
          monitor = "";
          size = "300, 50";
          outline_size = 2;
          dots_center = true;
        }
      ];
    };
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "hyprlock";
        before_sleep_cmd = "hyprlock";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "hyprlock";
        }
        {
          timeout = 600;
          on-timeout = "niri msg action power-off-monitors";
          on-resume = "niri msg action power-on-monitors";
        }
      ];
    };
  };

  # Scratchpad terminal bound to Super+grave.
  home.packages = [ pkgs.nirius ];

  # Bitwarden desktop <-> browser bridge (native messaging + passkeys).
  # Bitwarden writes its proxy/socket only to ~/.mozilla/native-messaging-hosts,
  # which flatpak browsers can't see, so their extension silently never pops the
  # desktop app (no autofill, no passkey prompt). This pins the override INI that
  # `flatpak override --filesystem=... app.zen_browser.zen` would write — no :ro,
  # the browser must connect() to the bridge socket. Rebuilt systems keep it.
  # Re-run `flatpak override --user --filesystem=/home/shika/.mozilla/native-messaging-hosts app.zen_browser.zen`
  # per additional browser flatpak (com.google.Chrome already has a copy).
  # Flatpak reads user overrides from XDG_DATA_HOME (xdg.dataFile, not configFile).
  xdg.dataFile."flatpak/overrides/app.zen_browser.zen".text = ''
    [Context]
    filesystems=/home/shika/.mozilla/native-messaging-hosts;
  '';
}
