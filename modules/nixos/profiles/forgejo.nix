{ config, ... }:

{
  imports = [ ./machine.nix ];

  services.forgejo-runner = {
    instances = {
      forgejo = {
        enable = true;
        settings.server.connections.default = {
          url = "https://forgejo.i.shikanime.studio";
          uuid = "5cc9b69c-45d8-4bb2-a472-f3eb5e04f859";
        };
        secrets.server.connections.default.token_url = config.sops.secrets.forgejo-runner-auth-token.path;
        labels = [
          "docker:docker://node:22-bookworm"
          "nixos-latest:docker://nixos/nix"
          "native:host"
        ];
      };
    };
  };

  sops = {
    secrets = {
      codeberg-runner-token = {
        sopsFile = ../../../secrets/builder.enc.yaml;
        restartUnits = [ "codeberg-runner-${config.networking.hostName}.service" ];
      };
      forgejo-runner-auth-token = {
        sopsFile = ../../../secrets/builder.enc.yaml;
        restartUnits = [ "forgejo-runner-forgejo.service" ];
      };
    };
    templates = {
      codeberg-runner-token.content = ''
        TOKEN=${config.sops.placeholder.codeberg-runner-token}
      '';
    };
  };

  virtualisation.docker = {
    daemon.settings = {
      fixed-cidr-v6 = "fd00::/80";
      ipv6 = true;
    };
    enable = true;
  };
}
