{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  imports = [
    ./ai.nix
    ./distributed.nix
    ./forgejo.nix
    ./server.nix
    ./wifi.nix
    ../users/builder.nix
    ../users/nishir.nix
  ];

  networking = {
    interfaces.br0.wakeOnLan.enable = true;

    # Ingress filtering on the cluster bridge.
    firewall = {
      extraCommands = ''
        iptables -I INPUT -i br+ -j ACCEPT
        ip6tables -I INPUT -i br+ -j ACCEPT
        iptables -I FORWARD -i br+ -j ACCEPT
        ip6tables -I FORWARD -i br+ -j ACCEPT
      '';
      extraStopCommands = ''
        iptables -D INPUT -i br+ -j ACCEPT 2>/dev/null || true
        ip6tables -D INPUT -i br+ -j ACCEPT 2>/dev/null || true
        iptables -D FORWARD -i br+ -j ACCEPT 2>/dev/null || true
        ip6tables -D FORWARD -i br+ -j ACCEPT 2>/dev/null || true
      '';
    };
  };

  services = {
    knix = {
      addons.flux = {
        instance.extraConfig.instance.sync = {
          interval = "1m";
          kind = "GitRepository";
          path = "clusters/nishir/overlays/tailnet";
          ref = "refs/heads/main";
          url = "https://github.com/shikanime-labs/manifests.git";
        };

        operator.extraConfig.web.configSecretName = "flux-operator-web";
      };

      coredns.extraConfig = {
        nodelocal.extraClusterDomains = [ "ts.net" ];

        servers = [
          {
            port = 53;
            zones = [
              {
                zone = ".";
                use_tcp = true;
              }
            ];
            plugins = [
              { name = "errors"; }
              {
                name = "health";
                configBlock = "lameduck 10s";
              }
              { name = "ready"; }
              {
                name = "kubernetes";
                parameters = "in-addr.arpa ip6.arpa";
                configBlock = ''
                  pods insecure
                  fallthrough in-addr.arpa ip6.arpa
                  ttl 30
                '';
              }
              {
                name = "prometheus";
                parameters = "0.0.0.0:9153";
              }
              {
                name = "rewrite";
                parameters = "name a2a.automata.i.shikanime.studio automata.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name accounts.i.shikanime.studio authelia.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name api.automata.i.shikanime.studio automata.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name authelia.i.shikanime.studio authelia.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name automata.i.shikanime.studio automata.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name bazarr.i.shikanime.studio bazarr.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name copyparty.i.shikanime.studio copyparty.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name dns.i.shikanime.studio blocky.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name flux.i.shikanime.studio flux-operator.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name forgejo.i.shikanime.studio forgejo.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name gitea-mirror.i.shikanime.studio gitea-mirror.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name grafana.i.shikanime.studio grafana.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name honcho.i.shikanime.studio honcho.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name immich.i.shikanime.studio immich.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name inference.i.shikanime.studio inference.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name jellyfin.i.shikanime.studio jellyfin.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name lidarr.i.shikanime.studio lidarr.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name llama-cpp.i.shikanime.studio llama-cpp.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name lldap.i.shikanime.studio lldap.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name logs.i.shikanime.studio victoria-logs.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name longhorn.i.shikanime.studio longhorn.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name maintainerr.i.shikanime.studio maintainerr.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name matrix-discord-media.i.shikanime.studio synapse.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name matrix.i.shikanime.studio synapse.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name mautrix-discord.i.shikanime.studio discord.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name mautrix-googlechat.i.shikanime.studio googlechat.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name mautrix-linkedin.i.shikanime.studio linkedin.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name mautrix-meta.i.shikanime.studio meta.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name mautrix-signal.i.shikanime.studio signal.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name mautrix-slack.i.shikanime.studio slack.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name mautrix-twitter.i.shikanime.studio twitter.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name mautrix-whatsapp.i.shikanime.studio whatsapp.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name metatube.i.shikanime.studio metatube.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name metrics.i.shikanime.studio grafana.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name prowlarr.i.shikanime.studio prowlarr.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name qbittorrent.i.shikanime.studio qbittorrent.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name radarr.i.shikanime.studio radarr.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name seerr.i.shikanime.studio seerr.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name sonarr.i.shikanime.studio sonarr.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name syncthing.i.shikanime.studio syncthing.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name vaultwarden.i.shikanime.studio vaultwarden.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "rewrite";
                parameters = "name whisparr.i.shikanime.studio whisparr.envoy-gateway-system.svc.cluster.local";
              }
              {
                name = "forward";
                parameters = ". /etc/resolv.conf";
              }
              {
                name = "cache";
                parameters = 30;
              }
              { name = "loop"; }
              { name = "reload"; }
              { name = "loadbalance"; }
            ];
          }
          {
            port = 53;
            zones = [ { zone = "ts.net"; } ];
            plugins = [
              { name = "errors"; }
              {
                name = "cache";
                parameters = 30;
                configBlock = ''
                  success 1024
                  denial 1024
                  serve_stale 10m
                  prefetch 1 1m 10%
                '';
              }
              {
                name = "forward";
                parameters = ". 10.96.99.99";
                configBlock = ''
                  max_fails 3
                  expire 10m
                  health_check 5s
                '';
              }
              { name = "loop"; }
            ];
          }
        ];
      };

      # Bridge interface — flannel, firewall, and sysctl rules all target br0.
      # Bonded on Beelink (bond0 -> br0), single-NIC on RPi (end0 -> br0).
      interface = "br0";

      # Use host-gw for flannel overlay — zero encapsulation overhead on same-LAN clusters
      canal.backend = "host-gw";
    };

    comin = {
      enable = lib.mkDefault true;
      # Node exporter listens on localhost only — vmagent scrapes from 127.0.0.1.
      exporter.listen_address = "127.0.0.1";
      remotes = [
        {
          name = "github";
          url = "https://github.com/shikanime-labs/machines.git";
          poller.period = 600;
        }
        {
          name = "forgejo";
          url = "https://forgejo.i.shikanime.studio/shikanime-labs/machines.git";
        }
      ];
    };

    # Local host metrics pipeline: node_exporter -> vmagent -> vminsert.
    prometheus.exporters = {
      node = {
        enable = true;
        listenAddress = "127.0.0.1";
        disabledCollectors = [
          "bcachefs"
          "fibrechannel"
          "infiniband"
          "ipvs"
          "mdadm"
          "nfsd"
          "os"
          "tapestats"
          "zfs"
        ];
        enabledCollectors = [
          "interrupts"
          "processes"
          "systemd"
          "tcpstat"
        ];
      };
      process.enable = true;
      smartctl.enable = true;
      systemd.enable = true;
    };

    vmagent = {
      enable = true;
      extraArgs = [ "-enableTCP6" ];
      prometheusConfig.scrape_configs = [
        {
          job_name = "comin";
          static_configs = [ { targets = [ "127.0.0.1:4243" ]; } ];
          relabel_configs = [
            {
              target_label = "instance";
              replacement = config.networking.hostName;
            }
            {
              target_label = "cluster";
              replacement = "nishir";
            }
          ];
        }
        {
          job_name = "node";
          static_configs = [ { targets = [ "127.0.0.1:9100" ]; } ];
          # Every host scrapes 127.0.0.1:9100 and remoteWrites the SAME
          # instance label, so VM merges all nodes into one series → garbage
          # rates. Rewrite to a unique per-host identity + real cluster label.
          relabel_configs = [
            {
              target_label = "instance";
              replacement = config.networking.hostName;
            }
            {
              target_label = "cluster";
              replacement = "nishir";
            }
            # Match the vmks bundled node rules, which select
            # job="node-exporter".
            {
              target_label = "job";
              replacement = "node-exporter";
            }
          ];
        }
      ];
      remoteWrite.url = "https://metrics.i.shikanime.studio/insert/0/prometheus";
    };

    vlagent = {
      enable = true;
      remoteWrite.url = "https://logs.i.shikanime.studio/insert/native";
      # Collect host logs incl. /var/log/pods/** (k8s container stdout: envoy
      # dataplane, controllers). Without a glob the file collector ingests nothing.
      extraArgs = [
        "-fileCollector.glob=/var/log/**/*.log"
        "-tmpDataPath=/var/cache/vlagent"
      ];
    };
  };

  sops = {
    secrets.flux-operator-web-client-secret = mkIf (config.services.knix.role == "server") {
      sopsFile = ../../../secrets/machine.enc.yaml;
      restartUnits = [ "systemd-tmpfiles-setup.service" ];
    };

    templates = mkIf (config.services.knix.role == "server") {
      "flux-operator-config.json".file = (pkgs.formats.json { }).generate "flux-operator-config.json" {
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

  systemd.tmpfiles.rules = [
    "a+ /var/log/pods - - - - user:vlagent:rX"
    "a+ /var/log/pods - - - - default:user:vlagent:rX"
    "d /var/lib/node_exporter/textfile_collector 0755 root root -"
  ]
  ++ (optionals (config.services.knix.role == "server") [
    "L+ /var/lib/rancher/rke2/server/manifests/flux-operator-config.json - - - - ${
      config.sops.templates."flux-operator-config.json".path
    }"
  ]);

  systemd.services = {
    # CPU power series. node_exporter's rapl collector reads
    # /sys/class/powercap, where the energy counters are 0400 root and kernfs
    # ignores runtime chmod/chgrp — verified: even 0444 world-readable returns
    # EACCES to the exporter user. The collector therefore needs the DAC
    # bypass; group ownership cannot express the grant (#1671).
    prometheus-node-exporter.serviceConfig = {
      CapabilityBoundingSet = [ "CAP_DAC_READ_SEARCH" ];
      AmbientCapabilities = [ "CAP_DAC_READ_SEARCH" ];
    };

    tailscale-serve-a2a = {
      description = "Expose Hermes A2A agent via Tailscale serve";
      after = [
        "tailscaled.service"
        "tailscale-serve.service"
      ];
      wants = [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = "5s";
      };
      script = ''
        ${getExe pkgs.tailscale} serve --yes --bg --https=9900 http://127.0.0.1:9900
      '';
    };

    tailscale-serve-api = {
      description = "Expose Hermes api_server via Tailscale serve";
      after = [
        "tailscaled.service"
        "tailscale-serve.service"
      ];
      wants = [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = "5s";
      };
      script = ''
        ${getExe pkgs.tailscale} serve --yes --bg --https=8642 http://127.0.0.1:8642
      '';
    };
  };
}
