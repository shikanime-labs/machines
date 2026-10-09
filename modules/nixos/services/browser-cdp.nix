{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.browser-cdp;
in
{
  options.services.browser-cdp = {
    enable = lib.mkEnableOption "headless Chromium exposing a CDP endpoint on localhost";

    package = lib.mkPackageOption pkgs "chromium" { };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9222;
      description = "Localhost TCP port for the CDP endpoint.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.browser-cdp = {
      description = "Headless Chromium CDP endpoint";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = lib.concatStringsSep " " [
          "${lib.getExe' cfg.package "chromium"}"
          "--headless=new"
          "--no-sandbox"
          "--disable-gpu"
          "--remote-debugging-address=127.0.0.1"
          "--remote-debugging-port=${toString cfg.port}"
          "--user-data-dir=/var/lib/browser-cdp"
        ];
        DynamicUser = true;
        StateDirectory = "browser-cdp";
        Restart = "on-failure";
      };
    };
  };
}
