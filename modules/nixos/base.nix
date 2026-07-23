{ config, ... }:

{
  imports = [
    ./minimal.nix
  ];

  nix = {
    extraOptions = ''
      !include ${config.sops.templates.nix-config.path}
    '';
    settings.experimental-features = [
      "flakes"
      "nix-command"
    ];
  };

  sops = {
    secrets.nix-access-token.reloadUnits = [ "nix-daemon.service" ];
    templates.nix-config.content = ''
      extra-access-tokens = "github.com=${config.sops.placeholder.nix-access-token}"
    '';
  };

  services = {
    comin = {
      enable = true;
      # Node exporter listens on localhost only — vmagent scrapes from 127.0.0.1.
      exporter.listen_address = "127.0.0.1";
      remotes = [
        {
          name = "origin";
          url = "https://github.com/shikanime-labs/machines.git";
        }
        {
          name = "origin";
          url = "https://forgejo.taila659a.ts.net/shikanime-labs/machines.git";
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
          "rapl"
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
      extraArgs = [
        "-enableTCP6"
      ];
      prometheusConfig.scrape_configs = [
        {
          job_name = "comin";
          static_configs = [
            { targets = [ "127.0.0.1:4243" ]; }
          ];
        }
        {
          job_name = "node";
          static_configs = [
            { targets = [ "127.0.0.1:9100" ]; }
          ];
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
          ];
        }
      ];
      remoteWrite.url = "https://telemetry.taila659a.ts.net/insert/0/prometheus";
    };
  };

  # Required for node-exporter textfile collector.
  systemd.tmpfiles.rules = [
    "d /var/lib/node_exporter/textfile_collector 0755 root root -"
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html)
  system.stateVersion = "26.05";
}
