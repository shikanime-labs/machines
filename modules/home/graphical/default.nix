{
  # Global Noctalia desktop shell theme for graphical Linux hosts.
  # NixOS-level programs.noctalia has no `settings`; theming is home-manager only,
  # so this is the shared home module all graphical users import.
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      # Disable dock exclusive-zone reservation (was upstream default true).
      # Bar smart auto-hide: reveal on pointer-edge approach (auto_hide), hide
      # when the active workspace has windows (smart_auto_hide). reserve_space kept
      # false per the merged "drop exclusive zone" decision; enable only if layout
      # jump bugs you.
      bar.main = {
        auto_hide = true;
        smart_auto_hide = true;
        reserve_space = false;
      };
      backdrop = {
        enabled = true;
        blur_intensity = 0.5; # default; 0.0 = no blur, 1.0 = max
        tint_intensity = 0.3; # 0.0 = no tint, 1.0 = opaque
      };
      calendar.enabled = true;
      location.auto_locate = true;
      plugins.enabled = [
        "noctalia/bitwarden"
        "noctalia/kaomoji"
        "noctalia/notes"
        "noctalia/screen_recorder"
        "noctalia/timer"
        "noctalia/translator"
        "noctalia/wallhaven"
      ];
      shell = {
        font = "Fira Code";
        font_family = "Fira Code";
        polkit_agent = true;
      };
      theme = {
        mode = "auto";
        source = "wallpaper";
        templates = {
          builtin_ids = [
            "ghostty"
            "gtk3"
            "gtk4"
            "helix"
            "niri"
            "qt"
            "starship"
          ];
          community_ids = [
            "bat"
            "discord"
            "neovim"
            "obs"
            "obsidian"
            "steam"
            "zed"
            "zen-browser"
          ];
        };
      };
      wallpaper.automation.enabled = true;
    };
  };

  # Niri compositor config deployed as real files (omarchy-style): config.kdl is
  # the entry point that includes looknfeel.kdl and binds.kdl, so per-concern
  # edits and diffs stay clean. niri resolves includes relative to the including
  # file and live-reloads on any of them (niri >= 25.11).
  xdg.configFile = {
    "niri/config.kdl".source = ./config/config.kdl;
    "niri/looknfeel.kdl".source = ./config/looknfeel.kdl;
    "niri/binds.kdl".source = ./config/binds.kdl;
  };
}
