{ config, ... }:

{
  imports = [ ./machine.nix ];

  services.forgejo-runner = {
    instances = {
      forgejo = {
        enable = true;
        labels = [
          "docker:docker://node:22-bookworm"
          "nixos-latest:docker://nixos/nix"
          "native:host"
        ];
        secrets.server.connections.default.token_url = config.sops.secrets.forgejo-runner-auth-token.path;
        settings.server.connections.default = {
          url = "https://forgejo.i.shikanime.studio";
          uuid = "5cc9b69c-45d8-4bb2-a472-f3eb5e04f859";
        };
      };
      codeberg = {
        enable = true;
        labels = [
          "docker:docker://node:22-bookworm"
          "nixos-latest:docker://nixos/nix"
          "native:host"
        ];
        secrets.server.connections.default.token_url = config.sops.secrets.codeberg-runner-auth-token.path;
        settings.server.connections.default = {
          url = "https://codeberg.org";
          uuid = "2386bbfc-04e5-4d87-9251-d08c67ab86fc";
        };
      };
    };
  };

  sops = {
    secrets = {
      codeberg-runner-auth-token = {
        sopsFile = ../../../secrets/builder.enc.yaml;
        restartUnits = [ "forgejo-runner-codeberg.service" ];
      };
      forgejo-runner-auth-token = {
        sopsFile = ../../../secrets/builder.enc.yaml;
        restartUnits = [ "forgejo-runner-forgejo.service" ];
      };
    };
    templates = { };
  };

  virtualisation.docker = {
    daemon.settings = {
      fixed-cidr-v6 = "fd00::/80";
      ipv6 = true;
    };
    enable = true;
  };
}
