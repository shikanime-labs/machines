{ config, pkgs, ... }:

{
  imports = [ ./machine.nix ];

  services.forgejo-runner = {
    package = pkgs.forgejo-runner;
    instances = {
      forgejo = {
        enable = true;
        url = "https://forgejo.i.shikanime.studio";
        labels = [
          "docker:docker://node:22-bookworm"
          "nixos-latest:docker://nixos/nix"
          "native:host"
        ];
        secrets.server.connections.default.token_url = config.sops.templates.forgejo-runner-token.path;
        settings.server.connections.default.uuid = "__placeholder__"; # placeholder; set real runner UUID after registration (old .runner file)
      };
    };
  };

  sops = {
    secrets = {
      codeberg-runner-token = {
        sopsFile = ../../../secrets/builder.enc.yaml;
        restartUnits = [ "codeberg-runner-${config.networking.hostName}.service" ];
      };
      forgejo-runner-token = {
        sopsFile = ../../../secrets/builder.enc.yaml;
        restartUnits = [ "forgejo-runner-${config.networking.hostName}.service" ];
      };
    };
    templates = {
      codeberg-runner-token.content = ''
        TOKEN=${config.sops.placeholder.codeberg-runner-token}
      '';
      forgejo-runner-token.content = ''
        TOKEN=${config.sops.placeholder.forgejo-runner-token}
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
