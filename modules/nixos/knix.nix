{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.knix;

  clusterCidr = lib.filter (cidr: cidr != null) [
    cfg.clusterCidrIPv4
    cfg.clusterCidrIPv6
  ];

  rke2ApiServerPort = 6443;
  rke2SupervisorPort = 9345;
  kubeletMetricsPort = 10250;
  etcdClientPort = 2379;
  etcdPeerPort = 2380;
  etcdMetricsPort = 2381;
  canalHealthCheckPort = 9099;
  wireguardPort = 51820;
  wireguardIPv6Port = 51821;

  nodePortRange = {
    from = 30000;
    to = 32767;
  };
in
with lib;
{
  options.knix = mkOption {
    type = types.submodule {
      options = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Knix RKE2 deployment.";
        };

        clusterCidrIPv4 = mkOption {
          type = types.nullOr types.str;
          default = "10.244.0.0/16";
          description = "The IPv4 pod CIDR passed to RKE2.";
        };

        clusterCidrIPv6 = mkOption {
          type = types.nullOr types.str;
          default = "fd00::/108";
          description = "The IPv6 pod CIDR passed to RKE2.";
        };

        nodeCidrMaskSize = mkOption {
          type = types.int;
          default = 24;
          description = "The IPv4 node CIDR mask size passed to the controller manager.";
        };

        nodeCidrMaskSizeIPv6 = mkOption {
          type = types.int;
          default = 112;
          description = "The IPv6 node CIDR mask size passed to the controller manager.";
        };

        serviceCidr = mkOption {
          type = types.nullOr types.str;
          default = "10.96.0.0/12,fd01::/108";
          description = "The service CIDR passed to RKE2.";
        };

        interface = mkOption {
          type = types.str;
          default = "enp1s0";
          description = "The WAN interface used for firewall policy.";
        };

        extraConfig = mkOption {
          type = types.attrsOf types.raw;
          default = { };
          description = "Additional direct values merged into services.rke2.";
        };

        nodeIP = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "The node IPs passed to RKE2.";
        };

        serverAddr = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "The server address passed to RKE2.";
        };

        tokenFile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "The token file passed to RKE2.";
        };

        flux = mkOption {
          type = types.submodule {
            options = {
              enable = mkOption {
                type = types.bool;
                default = true;
                description = "Flux bootstrap and management for RKE2";
              };

              instance = mkOption {
                type = types.submodule {
                  options = {
                    enable = mkOption {
                      type = types.bool;
                      default = true;
                      description = "Whether to deploy the Flux instance chart.";
                    };

                    extraConfig = mkOption {
                      type = types.attrsOf types.raw;
                      default = { };
                      description = "Additional raw configuration merged into the Flux instance chart.";
                    };

                    hash = mkOption {
                      type = types.str;
                      default = "sha256-A7ojoUGwSKt+Vi+kFFroNroUxrJzHdLdbrYidHgg8gs=";
                      description = "The Flux instance chart hash.";
                    };

                    version = mkOption {
                      type = types.str;
                      default = "0.46.0";
                      description = "The Flux instance chart version.";
                    };
                  };
                };
                default = { };
                description = "Flux instance chart settings.";
              };

              operator = mkOption {
                type = types.submodule {
                  options = {
                    enable = mkOption {
                      type = types.bool;
                      default = true;
                      description = "Whether to deploy the Flux operator chart.";
                    };

                    extraConfig = mkOption {
                      type = types.attrsOf types.raw;
                      default = { };
                      description = "Additional raw configuration merged into the Flux operator chart.";
                    };

                    hash = mkOption {
                      type = types.str;
                      default = "sha256-gt8bZ5oLw05lbUXGTzf6NBppAVuuKl9L9LH4jeROpkM=";
                      description = "The Flux operator chart hash.";
                    };

                    version = mkOption {
                      type = types.str;
                      default = "0.46.0";
                      description = "The Flux operator chart version.";
                    };
                  };
                };
                default = { };
                description = "Flux operator chart settings.";
              };

              path = mkOption {
                type = types.str;
                default = "clusters/nishir/overlays/tailnet";
                description = "The Kustomization path used by Flux.";
              };

              ref = mkOption {
                type = types.str;
                default = "refs/heads/main";
                description = "The Git ref Flux tracks.";
              };

              repoUrl = mkOption {
                type = types.str;
                default = "https://github.com/shikanime/manifests.git";
                description = "The Git repository Flux bootstraps from.";
              };

              tofu = mkOption {
                type = types.submodule {
                  options = {
                    enable = mkOption {
                      type = types.bool;
                      default = true;
                      description = "Whether to deploy the tofu-controller chart.";
                    };

                    extraConfig = mkOption {
                      type = types.attrsOf types.raw;
                      default = { };
                      description = "Additional raw configuration merged into the tofu-controller chart.";
                    };

                    hash = mkOption {
                      type = types.str;
                      default = "sha256-YQRWHQwNn+Du9LNcveCBzTnacRDtWNJHwvXxeIxtKcc=";
                      description = "The tofu-controller chart hash.";
                    };

                    version = mkOption {
                      type = types.str;
                      default = "0.16.2";
                      description = "The tofu-controller chart version.";
                    };
                  };
                };
                default = { };
                description = "tofu-controller chart settings.";
              };
            };
          };
          default = { };
          description = "Flux bootstrap and management settings.";
        };

        longhorn = mkOption {
          type = types.submodule {
            options = {
              enable = mkOption {
                type = types.bool;
                default = true;
                description = "Longhorn integration for RKE2";
              };

              mountRoot = mkOption {
                type = types.str;
                default = "/mnt";
                description = "The mount root scanned for additional Longhorn disks.";
              };

              storageReservedPercent = mkOption {
                type = types.int;
                default = 30;
                description = "The percentage of disk space reserved on additional Longhorn disks.";
              };
            };
          };
          default = { };
          description = "Longhorn integration for the Knix RKE2 stack.";
        };
      };
    };
    default = { };
    description = "Structured configuration for the Knix RKE2 stack.";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.rke2 = mkMerge [
        {
          enable = true;
          role = "server";
          cisHardening = true;
          manifests = {
            rke2-canal-config.content = {
              apiVersion = "helm.cattle.io/v1";
              kind = "HelmChartConfig";
              metadata = {
                name = "rke2-canal";
                namespace = "kube-system";
              };
              spec.valuesContent = builtins.toJSON {
                flannel = {
                  backend = "wireguard";
                  iface = cfg.interface;
                };
              };
            };

            rke2-coredns-config.content = {
              apiVersion = "helm.cattle.io/v1";
              kind = "HelmChartConfig";
              metadata = {
                name = "rke2-coredns";
                namespace = "kube-system";
              };
              spec.valuesContent = builtins.toJSON {
                nodelocal.enabled = true;
              };
            };

            rke2-multus-config.content = {
              apiVersion = "helm.cattle.io/v1";
              kind = "HelmChartConfig";
              metadata = {
                name = "rke2-multus";
                namespace = "kube-system";
              };
              spec.valuesContent = builtins.toJSON {
                manifests.dhcpDaemonSet = true;
              };
            };

            rke2-traefik-config.content = {
              apiVersion = "helm.cattle.io/v1";
              kind = "HelmChartConfig";
              metadata = {
                name = "rke2-traefik";
                namespace = "kube-system";
              };
              spec.valuesContent = builtins.toJSON {
                providers.kubernetesGateway.enabled = true;
              };
            };
          };
          extraFlags = [
            (optionalString (clusterCidr != [ ]) "--cluster-cidr=${concatStringsSep "," clusterCidr}")
            "--cni=multus,canal"
            "--ingress-controller=traefik"
            "--kube-controller-manager-arg=node-cidr-mask-size-ipv4=${toString cfg.nodeCidrMaskSize}"
            "--kube-controller-manager-arg=node-cidr-mask-size-ipv6=${toString cfg.nodeCidrMaskSizeIPv6}"
            (optionalString (cfg.serviceCidr != null) "--service-cidr=${cfg.serviceCidr}")
            "--secrets-encryption"
          ];
          gracefulNodeShutdown.enable = true;
        }
        cfg.extraConfig
        (optionalAttrs (cfg.nodeIP != null) { inherit (cfg) nodeIP; })
        (optionalAttrs (cfg.serverAddr != null) { inherit (cfg) serverAddr; })
        (optionalAttrs (cfg.tokenFile != null) { inherit (cfg) tokenFile; })
      ];

      networking.firewall = {
        extraCommands = ''
          # Keep public IPv6 egress off the WAN interface so runtimes fall back
          # to IPv4 while still allowing local and tailnet traffic.
          ip6tables -A OUTPUT -o ${cfg.interface} -d ::1/128 -j ACCEPT
          ip6tables -A OUTPUT -o ${cfg.interface} -d fe80::/10 -j ACCEPT
          ip6tables -A OUTPUT -o ${cfg.interface} -d fc00::/7 -j ACCEPT
          ip6tables -A OUTPUT -o ${cfg.interface} -d fd00::/108 -j ACCEPT
          ip6tables -A OUTPUT -o ${cfg.interface} -d fd01::/108 -j ACCEPT
          ip6tables -A OUTPUT -o ${cfg.interface} -d 2000::/3 -j REJECT --reject-with icmp6-addr-unreachable
        '';
        extraStopCommands = ''
          ip6tables -D OUTPUT -o ${cfg.interface} -d ::1/128 -j ACCEPT 2>/dev/null || true
          ip6tables -D OUTPUT -o ${cfg.interface} -d fe80::/10 -j ACCEPT 2>/dev/null || true
          ip6tables -D OUTPUT -o ${cfg.interface} -d fc00::/7 -j ACCEPT 2>/dev/null || true
          ip6tables -D OUTPUT -o ${cfg.interface} -d fd00::/108 -j ACCEPT 2>/dev/null || true
          ip6tables -D OUTPUT -o ${cfg.interface} -d fd01::/108 -j ACCEPT 2>/dev/null || true
          ip6tables -D OUTPUT -o ${cfg.interface} -d 2000::/3 -j REJECT --reject-with icmp6-addr-unreachable 2>/dev/null || true
        '';
        interfaces.${cfg.interface} = {
          allowedTCPPorts = [
            rke2ApiServerPort
            rke2SupervisorPort
            kubeletMetricsPort
            etcdClientPort
            etcdPeerPort
            etcdMetricsPort
            canalHealthCheckPort
          ];
          allowedUDPPorts = [
            wireguardPort
            wireguardIPv6Port
          ];
          allowedTCPPortRanges = [ nodePortRange ];
        };
      };
    }

    (mkIf cfg.flux.enable {
      services.rke2.autoDeployCharts = mkMerge [
        (optionalAttrs cfg.flux.instance.enable {
          flux = {
            createNamespace = true;
            extraDeploy = optional (cfg.flux.instance.extraConfig != { }) {
              apiVersion = "helm.cattle.io/v1";
              kind = "HelmChartConfig";
              metadata = {
                name = "flux";
                namespace = "kube-system";
              };
              spec.valuesContent = builtins.toJSON cfg.flux.instance.extraConfig;
            };
            extraFieldDefinitions.failurePolicy = "abort";
            hash = cfg.flux.instance.hash;
            name = "flux-instance";
            repo = "oci://ghcr.io/controlplaneio-fluxcd/charts/flux-instance";
            targetNamespace = "flux-system";
            values = {
              instance = {
                distribution = {
                  registry = "ghcr.io/fluxcd";
                  version = "2.x";
                };
                kustomize.patches = [
                  {
                    patch = ''
                      - op: add
                        path: /spec/decryption
                        value:
                          provider: sops
                          secretRef:
                            name: sops-age
                    '';
                    target.kind = "Kustomization";
                  }
                ];
                sync = {
                  interval = "1m";
                  kind = "GitRepository";
                  path = cfg.flux.path;
                  pullSecret = "";
                  ref = cfg.flux.ref;
                  url = cfg.flux.repoUrl;
                };
              };
            };
            version = cfg.flux.instance.version;
          };
        })
        (optionalAttrs cfg.flux.operator.enable {
          flux-operator = {
            createNamespace = true;
            extraDeploy = optional (cfg.flux.operator.extraConfig != { }) {
              apiVersion = "helm.cattle.io/v1";
              kind = "HelmChartConfig";
              metadata = {
                name = "flux-operator";
                namespace = "kube-system";
              };
              spec.valuesContent = builtins.toJSON cfg.flux.operator.extraConfig;
            };
            extraFieldDefinitions.failurePolicy = "abort";
            hash = cfg.flux.operator.hash;
            name = "flux-operator";
            repo = "oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator";
            targetNamespace = "flux-system";
            values = {
              web.config.authentication = {
                anonymous = {
                  groups = [ "system:masters" ];
                  username = "admin";
                };
                type = "Anonymous";
              };
            };
            version = cfg.flux.operator.version;
          };
        })
        (optionalAttrs cfg.flux.tofu.enable {
          tofu-controller = {
            createNamespace = true;
            extraDeploy = optional (cfg.flux.tofu.extraConfig != { }) {
              apiVersion = "helm.cattle.io/v1";
              kind = "HelmChartConfig";
              metadata = {
                name = "tofu-controller";
                namespace = "kube-system";
              };
              spec.valuesContent = builtins.toJSON cfg.flux.tofu.extraConfig;
            };
            extraFieldDefinitions.failurePolicy = "abort";
            hash = cfg.flux.tofu.hash;
            name = "tofu-controller";
            repo = "https://flux-iac.github.io/tofu-controller";
            targetNamespace = "flux-system";
            values = {
              awsPackage.install = false;
              runner.serviceAccount.allowedNamespaces = [
                "flux-system"
                "shikanime"
              ];
            };
            version = cfg.flux.tofu.version;
          };
        })
      ];

      systemd.services.rke2-flux-sops-age = {
        after = [ "rke2-server.service" ];
        description = "Create sops-age secret for flux-system";
        environment.KUBECONFIG = "/etc/rancher/rke2/rke2.yaml";
        preStart = ''
          until ${pkgs.kubectl}/bin/kubectl get namespace flux-system >/dev/null 2>&1; do
            sleep 1
          done
        '';
        script = ''
          if ! ${pkgs.kubectl}/bin/kubectl -n flux-system get secret sops-age >/dev/null 2>&1; then
            ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key | \
              ${pkgs.kubectl}/bin/kubectl -n flux-system create secret generic sops-age \
                --from-file=age.agekey=/dev/stdin \
                --dry-run=client -o yaml | ${pkgs.kubectl}/bin/kubectl apply -f -
          fi
        '';
        serviceConfig.Type = "oneshot";
        wants = [ "rke2-server.service" ];
      };
    })

    (mkIf cfg.longhorn.enable {
      boot.kernelModules = [
        "dm_crypt"
        "iscsi_tcp"
      ];

      services.openiscsi = {
        enable = true;
        name = "iqn.2026-06.io.shikanime:${config.networking.hostName}";
      };

      boot.supportedFilesystems = [ "nfs" ];

      environment.systemPackages = with pkgs; [
        cryptsetup
        lvm2
        nfs-utils
        openiscsi
      ];

      systemd.tmpfiles.rules = [
        "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
      ];

      services.rke2.nodeLabel = [
        "node.longhorn.io/create-default-disk=config"
      ];

      systemd.services.rke2-longhorn-default-disks-config = {
        description = "Apply Longhorn default-disks-config annotation";
        wants = [ "rke2-server.service" ];
        after = [ "rke2-server.service" ];
        wantedBy = [ "multi-user.target" ];
        environment.KUBECONFIG = "/etc/rancher/rke2/rke2.yaml";
        serviceConfig.Type = "oneshot";
        preStart = ''
          until ${pkgs.kubectl}/bin/kubectl get node ${config.networking.hostName} >/dev/null 2>&1; do
            sleep 1
          done
        '';
        script =
          let
            mountRoot = cfg.longhorn.mountRoot;
            storageReservedPercent = toString cfg.longhorn.storageReservedPercent;
          in
          ''
            disk_source() {
              mount_path="$1"

              ${pkgs.util-linux}/bin/findmnt -n -o SOURCE --target "$mount_path" 2>/dev/null \
                | ${pkgs.coreutils}/bin/tail -n 1 || true
            }

            disk_tags() {
              mount_path="$1"
              source="$(disk_source "$mount_path")"

              rotational="$(${pkgs.util-linux}/bin/lsblk -ndo ROTA "$source" 2>/dev/null \
                | ${pkgs.coreutils}/bin/head -n 1 \
                | ${pkgs.gnused}/bin/sed 's/[[:space:]]//g')"

              if [ -z "$rotational" ]; then
                return 1
              elif [ "$rotational" = "1" ]; then
                printf '%s\n' '["hdd"]'
              else
                printf '%s\n' '["ssd"]'
              fi
            }

            storage_reserved() {
              mount_path="$1"
              storage_reserved_percent="$2"

              size="$(${pkgs.coreutils}/bin/df -B1 --output=size "$mount_path" \
                | ${pkgs.coreutils}/bin/tail -n 1 \
                | ${pkgs.gnused}/bin/sed 's/[[:space:]]//g')"
              printf '%s\n' "$((size * storage_reserved_percent / 100))"
            }

            disk_config_entry() {
              mount_path="$1"
              storage_reserved_percent="$2"

              if ! ${pkgs.util-linux}/bin/mountpoint -q "$mount_path"; then
                return
              fi

              tags="$(disk_tags "$mount_path")"
              if [ -z "$tags" ]; then
                return
              fi

              longhorn_path="$mount_path/longhorn"
              mkdir -p "$longhorn_path"

              ${pkgs.jq}/bin/jq -nc \
                --arg path "$longhorn_path/" \
                --argjson tags "$tags" \
                --argjson storageReserved "$(storage_reserved "$mount_path" "$storageReservedPercent")" \
                '{
                  path: $path,
                  allowScheduling: true,
                  storageReserved: $storageReserved,
                  tags: $tags
                }'
            }

            longhornDefaultDisksConfig="$(
              {
                ${pkgs.jq}/bin/jq -nc '{
                  path: "/var/lib/longhorn/",
                  allowScheduling: true
                }'
                for mount_path in ${mountRoot}/*; do
                  if [ -d "$mount_path" ]; then
                    disk_config_entry "$mount_path" ${storageReservedPercent}
                  fi
                done
              } | ${pkgs.jq}/bin/jq -sc '.'
            )"

            ${pkgs.kubectl}/bin/kubectl annotate node ${config.networking.hostName} \
              node.longhorn.io/default-disks-config="$longhornDefaultDisksConfig" \
              --overwrite
          '';
      };
    })
  ]);
}
