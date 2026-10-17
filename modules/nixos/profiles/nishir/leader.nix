{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  jsonFormat = pkgs.formats.json { };
in
{
  imports = [
    ./base.nix
  ];

  sops = {
    secrets.flux-operator-web-client-secret = mkIf (config.services.knix.role == "server") {
      sopsFile = ../../../../secrets/machine.enc.yaml;
      restartUnits = [ "systemd-tmpfiles-setup.service" ];
    };

    templates = mkIf (config.services.knix.role == "server") {
      "flux-operator-config.json".file = jsonFormat.generate "flux-operator-config.json" {
        apiVersion = "v1";
        kind = "Secret";
        metadata = {
          name = "flux-operator-web";
          namespace = "flux-system";
        };
        type = "Opaque";
        stringData."config.yaml" = builtins.toJSON {
          apiVersion = "web.fluxcd.controlplane.io/v1";
          kind = "Config";
          spec = {
            baseURL = "https://flux.i.shikanime.studio";
            authentication = {
              type = "OAuth2";
              oauth2 = {
                provider = "OIDC";
                clientID = "flux";
                clientSecret = config.sops.placeholder."flux-operator-web-client-secret";
                issuerURL = "https://accounts.i.shikanime.studio";
                scopes = [
                  "openid"
                  "profile"
                  "email"
                  "groups"
                  "offline_access"
                ];
              };
            };
          };
        };
      };
    };
  };

  systemd.tmpfiles.rules = mkIf (config.services.knix.role == "server") [
    "L+ /var/lib/rancher/rke2/server/manifests/flux-operator-config.json - - - - ${
      config.sops.templates."flux-operator-config.json".path
    }"
  ];

  services = {
    # Expose RKE2 API (9345) and Kubernetes API (6443) as a single Tailscale Service.
    tailscale.serve = {
      enable = true;
      services.nishir = {
        advertised = true;
        endpoints = {
          "tcp:6443" = "tcp://127.0.0.1:6443";
          "tcp:9345" = "tcp://127.0.0.1:9345";
        };
      };
    };
  };
}
