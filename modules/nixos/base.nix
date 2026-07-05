{ config, ... }:

{
  imports = [
    ./minimal.nix
  ];

  nix.extraOptions = ''
    !include ${config.sops.templates.nix-config.path}
  '';

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
        }
        {
          job_name = "kube-controller-manager";
          scheme = "https";
          tls_config = {
            ca_file = "/var/lib/rancher/rke2/server/tls/server-ca.crt";
            cert_file = "/var/lib/rancher/rke2/server/tls/client-admin.crt";
            key_file = "/var/lib/rancher/rke2/server/tls/client-admin.key";
            insecure_skip_verify = true;
          };
          static_configs = [
            { targets = [ "127.0.0.1:10257" ]; }
          ];
        }
        {
          job_name = "kube-etcd";
          scheme = "https";
          tls_config = {
            ca_file = "/var/lib/rancher/rke2/server/tls/etcd/server-ca.crt";
            cert_file = "/var/lib/rancher/rke2/server/tls/etcd/client.crt";
            key_file = "/var/lib/rancher/rke2/server/tls/etcd/client.key";
            insecure_skip_verify = true; # Prevents IP Subject Alternative Name (SAN) mismatch errors on localhost
          };
          static_configs = [
            { targets = [ "127.0.0.1:2379" ]; }
          ];
        }
        {
          job_name = "kube-proxy";
          scheme = "https";
          tls_config = {
            ca_file = "/var/lib/rancher/rke2/server/tls/server-ca.crt";
            cert_file = "/var/lib/rancher/rke2/server/tls/client-admin.crt";
            key_file = "/var/lib/rancher/rke2/server/tls/client-admin.key";
            insecure_skip_verify = true;
          };
          static_configs = [
            { targets = [ "127.0.0.1:10249" ]; }
          ];
        }
        {
          job_name = "kube-scheduler";
          scheme = "https";
          tls_config = {
            ca_file = "/var/lib/rancher/rke2/server/tls/server-ca.crt";
            cert_file = "/var/lib/rancher/rke2/server/tls/client-admin.crt";
            key_file = "/var/lib/rancher/rke2/server/tls/client-admin.key";
            insecure_skip_verify = true;
          };
          static_configs = [
            { targets = [ "127.0.0.1:10259" ]; }
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
