{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.shikanime.rke2;
  isAgent = cfg.role == "agent";
  isServer = cfg.role == "server";
in
{
  options.shikanime.rke2 = {
    enable = lib.mkEnableOption "RKE2";

    role = lib.mkOption {
      type = lib.types.enum [
        "server"
        "agent"
      ];
      default = "server";
    };

    serverAddr = lib.mkOption {
      type = lib.types.str;
      default = "";
    };

    tokenSecret = lib.mkOption {
      type = lib.types.str;
      default = "rke2-token";
    };

    cisHardening = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    secretsEncryption = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    dualStack = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };

      clusterCIDR = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "10.42.0.0/16"
          "fd42:10:42::/56"
        ];
      };

      serviceCIDR = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "10.43.0.0/16"
          "fd42:10:43::/112"
        ];
      };

      clusterDNS = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "10.43.0.10"
          "fd42:10:43::a"
        ];
      };
    };

    canalBackend = lib.mkOption {
      type = lib.types.enum [
        "vxlan"
        "wireguard"
      ];
      default = "wireguard";
    };

    flannelIface = lib.mkOption {
      type = lib.types.str;
      default = "tailscale0";
    };

    bootstrap = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };

      repoUrl = lib.mkOption {
        type = lib.types.str;
        default = "https://github.com/shikanime/manifests.git";
      };

      ref = lib.mkOption {
        type = lib.types.str;
        default = "refs/heads/main";
      };

      path = lib.mkOption {
        type = lib.types.str;
        default = "clusters/nishir/overlays/tailnet";
      };

      hostName = lib.mkOption {
        type = lib.types.str;
        default = "${config.networking.hostName}-flux";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(isAgent && cfg.serverAddr == "");
        message = "shikanime.rke2.serverAddr must be set when shikanime.rke2.role = \"agent\".";
      }
    ];

    services.rke2 = {
      inherit (cfg) role cisHardening;
      enable = true;
      cni = "canal";
      gracefulNodeShutdown.enable = true;
      serverAddr = lib.mkIf isAgent cfg.serverAddr;
      tokenFile = lib.mkIf isAgent config.sops.secrets.${cfg.tokenSecret}.path;
      extraFlags =
        (lib.optionals cfg.secretsEncryption [ "--secrets-encryption" ])
        ++ (lib.optionals cfg.dualStack.enable [
          "--cluster-cidr=${lib.concatStringsSep "," cfg.dualStack.clusterCIDR}"
          "--service-cidr=${lib.concatStringsSep "," cfg.dualStack.serviceCIDR}"
          "--cluster-dns=${lib.concatStringsSep "," cfg.dualStack.clusterDNS}"
        ]);
    };

    services.rke2.manifests.rke2-canal-config = lib.mkIf isServer {
      target = "rke2-canal-config.yaml";
      content = {
        apiVersion = "helm.cattle.io/v1";
        kind = "HelmChartConfig";
        metadata = {
          name = "rke2-canal";
          namespace = "kube-system";
        };
        spec = {
          valuesContent = ''
            flannel:
              backend: "${cfg.canalBackend}"
              iface: "${cfg.flannelIface}"
          '';
        };
      };
    };

    services.rke2.autoDeployCharts = lib.mkIf (isServer && cfg.bootstrap.enable) {
      flux = {
        repo = "oci://ghcr.io/controlplaneio-fluxcd/charts/flux-instance";
        name = "flux-instance";
        hash = "sha256-A7ojoUGwSKt+Vi+kFFroNroUxrJzHdLdbrYidHgg8gs=";
        version = "0.46.0";
        targetNamespace = "flux-system";
        createNamespace = true;
        values = {
          instance = {
            distribution = {
              registry = "ghcr.io/fluxcd";
              version = "2.x";
            };
            kustomize = {
              patches = [
                {
                  patch = ''
                    - op: add
                      path: /spec/decryption
                      value:
                        provider: sops
                        secretRef:
                          name: sops-age
                  '';
                  target = {
                    kind = "Kustomization";
                  };
                }
              ];
            };
            sync = {
              interval = "1m";
              kind = "GitRepository";
              path = cfg.bootstrap.path;
              pullSecret = "";
              ref = cfg.bootstrap.ref;
              url = cfg.bootstrap.repoUrl;
            };
          };
        };
      };

      flux-operator = {
        repo = "oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator";
        name = "flux-operator";
        hash = "sha256-gt8bZ5oLw05lbUXGTzf6NBppAVuuKl9L9LH4jeROpkM=";
        version = "0.46.0";
        targetNamespace = "flux-system";
        createNamespace = true;
        values = {
          healthcheck.enabled = true;
          web = {
            config = {
              authentication = {
                type = "Anonymous";
                anonymous = {
                  username = "admin";
                  groups = [ "system:masters" ];
                };
              };
            };
            ingress = {
              enabled = true;
              className = "tailscale";
              annotations = {
                "tailscale.com/tags" = "tag:web";
              };
              hosts = [
                {
                  host = cfg.bootstrap.hostName;
                  paths = [
                    {
                      path = "/";
                      pathType = "ImplementationSpecific";
                    }
                  ];
                }
              ];
              tls = [
                {
                  hosts = [ cfg.bootstrap.hostName ];
                }
              ];
            };
            rbac.createRoles = true;
          };
        };
      };

      tofu-controller = {
        repo = "https://flux-iac.github.io/tofu-controller";
        name = "tofu-controller";
        hash = "sha256-YQRWHQwNn+Du9LNcveCBzTnacRDtWNJHwvXxeIxtKcc=";
        version = "0.16.2";
        targetNamespace = "flux-system";
        createNamespace = true;
        values = {
          awsPackage.install = false;
          runner.allowedNamespaces = [
            "flux-system"
            "shikanime"
          ];
        };
      };
    };

    systemd.services.rke2-sops-age = lib.mkIf (isServer && cfg.bootstrap.enable) {
      wants = [ "rke2-server.service" ];
      after = [ "rke2-server.service" ];
      environment = {
        KUBECONFIG = "/etc/rancher/rke2/rke2.yaml";
      };
      serviceConfig = {
        Type = "oneshot";
        Restart = "on-failure";
        RestartSec = "10s";
        StartLimitIntervalSec = 0;
      };
      preStart = ''
        set -euo pipefail

        [ -n "$(${pkgs.iproute2}/bin/ss -H -lnt sport = :6443 2>/dev/null)" ]
        ${pkgs.kubectl}/bin/kubectl get --raw=/readyz >/dev/null 2>&1
        ${pkgs.kubectl}/bin/kubectl get namespace flux-system >/dev/null 2>&1
      '';
      script = ''
        set -euo pipefail

        if ! ${pkgs.kubectl}/bin/kubectl -n flux-system get secret sops-age >/dev/null 2>&1; then
          ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key | \
            ${pkgs.kubectl}/bin/kubectl -n flux-system create secret generic sops-age \
              --from-file=age.agekey=/dev/stdin \
              --dry-run=client -o yaml | ${pkgs.kubectl}/bin/kubectl apply -f -
        fi
      '';
    };
  };
}
