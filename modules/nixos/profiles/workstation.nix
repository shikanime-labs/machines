{ config, pkgs, ... }:

{
  imports = [ ./machine.nix ];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
    ];
  };

  programs.gnupg.agent = {
    enable = true;
    enableExtraSocket = true;
    pinentryPackage = pkgs.pinentry-all;
    settings.default-cache-ttl = 60 * 60;
  };

  virtualisation.docker = {
    autoPrune.enable = true;
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # Workstation observability: metrics + logs only, no k8s container paths.
  # comin intentionally absent — workstations deploy outside the cluster
  # channel.
  services = {
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
          job_name = "node";
          static_configs = [ { targets = [ "127.0.0.1:9100" ]; } ];
          relabel_configs = [
            {
              target_label = "instance";
              replacement = config.networking.hostName;
            }
            {
              target_label = "cluster";
              replacement = "workstation";
            }
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
      extraArgs = [
        "-fileCollector.glob=/var/log/*.log"
        "-tmpDataPath=/var/cache/vlagent"
      ];
    };
  };

  systemd.tmpfiles.rules = [ "d /var/lib/node_exporter/textfile_collector 0755 root root -" ];
}
