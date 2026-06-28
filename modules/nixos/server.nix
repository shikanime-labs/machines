{ pkgs, ... }:

{
  imports = [
    ./node.nix
  ];

  services = {
    gitea-actions-runner.package = pkgs.forgejo-runner;

    knix = {
      enable = true;
      addons = {
        flux = {
          instance.extraConfig.instance.sync = {
            interval = "1m";
            kind = "GitRepository";
            path = "clusters/nishir/overlays/tailnet";
            pullSecret = "";
            ref = "refs/heads/main";
            url = "https://github.com/shikanime-labs/manifests.git";
          };

          operator.extraConfig.web.ingress = {
            enabled = true;
            className = "tailscale";
            annotations."tailscale.com/tags" = "tag:web";
            hosts = [
              {
                host = "nishir-flux";
                paths = [
                  {
                    path = "/";
                    pathType = "ImplementationSpecific";
                  }
                ];
              }
            ];
            tls = [
              { hosts = [ "nishir-flux" ]; }
            ];
          };
        };
        longhorn.extraConfig.recurringJobSelector = {
          enable = true;
          jobList = [
            {
              name = "standard";
              isGroup = true;
            }
          ];
        };
      };
      addons.traefik.extraConfig.ports = {
        syncthing = {
          port = 22000;
          expose.default = true;
          exposedPort = 22000;
          protocol = "TCP";
        };
        syncthing-udp = {
          port = 22000;
          expose.default = true;
          exposedPort = 22000;
          protocol = "UDP";
        };
      };
      tlsSan = [
        "ashira.taila659a.ts.net"
        "fushi.taila659a.ts.net"
        "manash.taila659a.ts.net"
        "minish.taila659a.ts.net"
        "nalsha.taila659a.ts.net"
        "nemishi.taila659a.ts.net"
        "nishir.taila659a.ts.net"
      ];
    };
  };

  users.users.builder = {
    isNormalUser = true;
    home = "/home/builder";
    useDefaultShell = true;
  };

  virtualisation.docker = {
    daemon.settings = {
      fixed-cidr-v6 = "fd00::/80";
      ipv6 = true;
    };
    enable = true;
  };
}
