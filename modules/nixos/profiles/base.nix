{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./minimal.nix
  ];

  # Colemak at the OS level (TTY + localed -> niri reads it).
  colemak.enable = true;

  # Unicode console font so the bare TTY can actually draw those glyphs
  # (Cyrillic, box-drawing, etc.) instead of tofu blocks.
  console.font = "Lat2-Terminus16";

  # UTF-8 locale so the TTY (and everything else) emits/renders multibyte
  # and special characters instead of falling back to the C locale.
  i18n.defaultLocale = "en_US.UTF-8";

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
      extra-access-tokens = github.com=${config.sops.placeholder.nix-access-token}
    '';
  };

  services = {
    comin = {
      enable = true;
      # Node exporter listens on localhost only — vmagent scrapes from 127.0.0.1.
      exporter.listen_address = "127.0.0.1";
      remotes = [
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
      nvidia-gpu = lib.mkIf config.hardware.nvidia.enabled {
        enable = true;
        listenAddress = "127.0.0.1";
      };
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
        {
          job_name = "nvidia-gpu";
          static_configs = [
            { targets = [ "127.0.0.1:9835" ]; }
          ];
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
      remoteWrite.url = "https://telemetry.i.shikanime.studio/insert/0/prometheus";
    };
  };

  systemd = {
    # Host log pipeline: journald -> vlagent -> vlinsert.
    services.vlagent = {
      description = "VictoriaLogs agent (host journal -> victorialogs)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.vlagent}/bin/vlagent -remoteWrite.url=https://logs.i.shikanime.studio/insert/0/logs";
        User = "vlagent";
        SupplementaryGroups = [ "systemd-journal" ];
        Restart = "always";
        RestartSec = "5s";
        DynamicUser = true;
      };
    };

    # Required for node-exporter textfile collector.
    tmpfiles.rules = [
      "d /var/lib/node_exporter/textfile_collector 0755 root root -"
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html)
  system.stateVersion = "26.05";
}
