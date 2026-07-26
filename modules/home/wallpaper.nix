{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  # Per-user wallpaper rotation: ship the script and drive it via a systemd
  # user service + hourly timer. User-session only (swww is a Wayland daemon),
  # so this is a systemd.user unit, not a system unit.
  home.file.".local/bin/wallpaper-rotate" = {
    source = ../../scripts/wallpaper-rotate.sh;
    executable = true;
  };

  systemd.user.services.wallpaper-rotate = {
    Unit = {
      Description = "Rotate desktop wallpaper";
      # ponytail: no hard After= on swww-daemon; the script degrades gracefully
      # (logged error) when the setter is unavailable, so a missing daemon never
      # wedges the unit.
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.local/bin/wallpaper-rotate";
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.timers.wallpaper-rotate = {
    Unit.Description = "Hourly wallpaper rotation timer";
    Timer = {
      # ponytail: hourly cadence; change OnCalendar for a different interval.
      OnCalendar = "hourly";
      Persistent = true; # run on next boot if the host was off at the tick
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
