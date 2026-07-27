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

  xdg.configFile."niri/config.kdl".text = ''
    // Niri configuration for Noctalia integration (Noctalia v5 Niri compositor spec).

    // Open the Firefox picture-in-picture player as floating by default.
    window-rule {
        match app-id=r#"firefox$"# title="^Picture-in-Picture$"
        open-floating true
    }

    // ── Noctalia custom window-rules ──
    // Rounded corners for all windows (was upstream default-commented example at r=12).
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

    // Suppress the "Important Hotkeys" overlay popup at login; Mod+Shift+Slash still shows it.
    hotkey-overlay {
        skip-at-startup
    }

    // Required, or Noctalia notification actions / window activation won't work.
    debug {
        honor-xdg-activation-with-invalid-serial
    }

    binds {
        // Mod-Shift-/, which is usually the same as Mod-?,
        // shows a list of important hotkeys.
        Mod+Shift+Slash { show-hotkey-overlay; }

        // Suggested binds for running programs: terminal, app launcher, screen locker.
        Mod+T hotkey-overlay-title="Open a Terminal: ghostty" { spawn "ghostty"; }
        Mod+D hotkey-overlay-title="Run an Application: fuzzel" { spawn "fuzzel"; }

        // ── Noctalia shell integration (custom) ──
        Mod+Space { spawn-sh "noctalia msg panel-toggle launcher"; }
        Mod+S { spawn-sh "noctalia msg panel-toggle control-center"; }
        Alt+Tab { spawn-sh "noctalia msg window-switcher"; }

        // Lock the screen via Noctalia (swaylock not installed; Noctalia owns locking).
        Super+Alt+L hotkey-overlay-title="Lock the Screen" { spawn-sh "noctalia msg session lock"; }

        // Noctalia volume control (overrides default wpctl binds).
        XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "noctalia msg volume-up"; }
        XF86AudioLowerVolume allow-when-locked=true { spawn-sh "noctalia msg volume-down"; }
        XF86AudioMute        allow-when-locked=true { spawn-sh "noctalia msg volume-mute"; }
        XF86AudioMicMute     allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; }

        // Example media keys mapping using playerctl.
        XF86AudioPlay        allow-when-locked=true { spawn-sh "playerctl play-pause"; }
        XF86AudioStop        allow-when-locked=true { spawn-sh "playerctl stop"; }
        XF86AudioPrev        allow-when-locked=true { spawn-sh "playerctl previous"; }
        XF86AudioNext        allow-when-locked=true { spawn-sh "playerctl next"; }

        // Noctalia brightness control (overrides default brightnessctl binds).
        XF86MonBrightnessUp allow-when-locked=true { spawn-sh "noctalia msg brightness-up"; }
        XF86MonBrightnessDown allow-when-locked=true { spawn-sh "noctalia msg brightness-down"; }

        // Open/close the Overview.
        Mod+O repeat=false { toggle-overview; }

        Mod+Q repeat=false { close-window; }

        Mod+Left  { focus-column-left; }
        Mod+Down  { focus-window-down; }
        Mod+Up    { focus-window-up; }
        Mod+Right { focus-column-right; }
        Mod+H     { focus-column-left; }
        Mod+J     { focus-window-down; }
        Mod+K     { focus-window-up; }
        Mod+L     { focus-column-right; }

        Mod+Ctrl+Left  { move-column-left; }
        Mod+Ctrl+Down  { move-window-down; }
        Mod+Ctrl+Up    { move-window-up; }
        Mod+Ctrl+Right { move-column-right; }
        Mod+Ctrl+H     { move-column-left; }
        Mod+Ctrl+J     { move-window-down; }
        Mod+Ctrl+K     { move-window-up; }
        Mod+Ctrl+L     { move-column-right; }

        Mod+Home { focus-column-first; }
        Mod+End  { focus-column-last; }
        Mod+Ctrl+Home { move-column-to-first; }
        Mod+Ctrl+End  { move-column-to-last; }

        Mod+Shift+Left  { focus-monitor-left; }
        Mod+Shift+Down  { focus-monitor-down; }
        Mod+Shift+Up    { focus-monitor-up; }
        Mod+Shift+Right { focus-monitor-right; }
        Mod+Shift+H     { focus-monitor-left; }
        Mod+Shift+J     { focus-monitor-down; }
        Mod+Shift+K     { focus-monitor-up; }
        Mod+Shift+L     { focus-monitor-right; }

        Mod+Shift+Ctrl+Left  { move-column-to-monitor-left; }
        Mod+Shift+Ctrl+Down  { move-column-to-monitor-down; }
        Mod+Shift+Ctrl+Up    { move-column-to-monitor-up; }
        Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }
        Mod+Shift+Ctrl+H     { move-column-to-monitor-left; }
        Mod+Shift+Ctrl+J     { move-column-to-monitor-down; }
        Mod+Shift+Ctrl+K     { move-column-to-monitor-up; }
        Mod+Shift+Ctrl+L     { move-column-to-monitor-right; }

        Mod+Page_Down      { focus-workspace-down; }
        Mod+Page_Up        { focus-workspace-up; }
        Mod+U              { focus-workspace-down; }
        Mod+I              { focus-workspace-up; }
        Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
        Mod+Ctrl+Page_Up   { move-column-to-workspace-up; }
        Mod+Ctrl+U         { move-column-to-workspace-down; }
        Mod+Ctrl+I         { move-column-to-workspace-up; }

        Mod+Shift+Page_Down { move-workspace-down; }
        Mod+Shift+Page_Up   { move-workspace-up; }
        Mod+Shift+U         { move-workspace-down; }
        Mod+Shift+I         { move-workspace-up; }

        Mod+WheelScrollDown      cooldown-ms=150 { focus-workspace-down; }
        Mod+WheelScrollUp        cooldown-ms=150 { focus-workspace-up; }
        Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
        Mod+Ctrl+WheelScrollUp   cooldown-ms=150 { move-column-to-workspace-up; }

        Mod+WheelScrollRight      { focus-column-right; }
        Mod+WheelScrollLeft       { focus-column-left; }
        Mod+Ctrl+WheelScrollRight { move-column-right; }
        Mod+Ctrl+WheelScrollLeft  { move-column-left; }

        Mod+Shift+WheelScrollDown      { focus-column-right; }
        Mod+Shift+WheelScrollUp        { focus-column-left; }
        Mod+Ctrl+Shift+WheelScrollDown { move-column-right; }
        Mod+Ctrl+Shift+WheelScrollUp   { move-column-left; }

        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+6 { focus-workspace 6; }
        Mod+7 { focus-workspace 7; }
        Mod+8 { focus-workspace 8; }
        Mod+9 { focus-workspace 9; }
        Mod+Ctrl+1 { move-column-to-workspace 1; }
        Mod+Ctrl+2 { move-column-to-workspace 2; }
        Mod+Ctrl+3 { move-column-to-workspace 3; }
        Mod+Ctrl+4 { move-column-to-workspace 4; }
        Mod+Ctrl+5 { move-column-to-workspace 5; }
        Mod+Ctrl+6 { move-column-to-workspace 6; }
        Mod+Ctrl+7 { move-column-to-workspace 7; }
        Mod+Ctrl+8 { move-column-to-workspace 8; }
        Mod+Ctrl+9 { move-column-to-workspace 9; }

        // Move the focused window in and out of a column.
        Mod+BracketLeft  { consume-or-expel-window-left; }
        Mod+BracketRight { consume-or-expel-window-right; }

        // Consume one window from the right to the bottom of the focused column.
        Mod+Comma  { spawn-sh "noctalia msg settings-toggle"; }
        // Expel the bottom window from the focused column to the right.
        Mod+Period { expel-window-from-column; }

        Mod+R { switch-preset-column-width; }
        Mod+Shift+R { switch-preset-column-width-back; }
        Mod+Ctrl+Shift+R { switch-preset-window-height; }
        Mod+Ctrl+R { reset-window-height; }

        Mod+F { maximize-column; }
        Mod+Shift+F { fullscreen-window; }
        Mod+M { maximize-window-to-edges; }
        Mod+Ctrl+F { expand-column-to-available-width; }

        Mod+C { center-column; }
        Mod+Ctrl+C { center-visible-columns; }

        Mod+Minus { set-column-width "-10%"; }
        Mod+Equal { set-column-width "+10%"; }
        Mod+Shift+Minus { set-window-height "-10%"; }
        Mod+Shift+Equal { set-window-height "+10%"; }

        Mod+V       { toggle-window-floating; }
        Mod+Shift+V { switch-focus-between-floating-and-tiling; }

        Mod+W { toggle-column-tabbed-display; }

        Print { screenshot; }
        Ctrl+Print { screenshot-screen; }
        Alt+Print { screenshot-window; }

        Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }

        Mod+Shift+E { quit; }
        Ctrl+Alt+Delete { quit; }

        Mod+Shift+P { power-off-monitors; }
    }

    // Laptop: lock + suspend on lid close (ishtar). logind HandleLidSwitch=ignore
    // set at the NixOS level so systemd doesn't also suspend.
    switch-events {
        lid-close { spawn "noctalia" "msg" "session" "lock-and-suspend"; }
    }

    // X11 bridge for legacy X apps
    xwayland-satellite {}
  '';
}
