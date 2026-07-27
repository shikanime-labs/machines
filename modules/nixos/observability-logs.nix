{ lib, pkgs, ... }:

{
  options = {
    services.observability-logs = lib.mkOption {
      type = lib.types.null_or (lib.types.submodule({
        enable = lib.mkEnableOption "observability log shipping";
        settings = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = {};
        };
      }));
      default = null;
    };
  };

  config = lib.mkIf (config.services.observability-logs != null && config.services.observability-logs.enable) {
    services.promtail = {
      enable = true;
      settings = config.services.observability-logs.settings // {
        clients = (config.services.observability-logs.settings.clients or {}) // {
          default = {
            endpoint = [
              "http://127.0.0.1:3100/loki/api/v1/push"
            ];
          };
        };
        positions = {
          filename = "/tmp/positions.yaml";
        };
        server = {
          http_listen_port = 9080;
          grpc_listen_port = 0;
        };
      };
    };
    environment.systemPackages = [ pkgs.promtail ];
  };
}

