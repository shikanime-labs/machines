{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  imports = [
    ./base.nix
  ];

  # 32 = SHUTDOWN_IOERROR. This specifically targets I/O failures.
  # When XFS encounters a permanent I/O error, it panics the kernel.
  boot.kernel.sysctl."fs.xfs.panic_mask" = 32;

  networking = {
    firewall = {
      # Cluster -> tailnet egress. Pods route via the node (flannel host-gw),
      # so their traffic reaches the host on the CNI bridge (cni0) and must be
      # forwarded out tailscale0 to reach tailnet CGNAT addresses
      # (100.64.0.0/10, e.g. *.ts.net). The node already holds these routes via
      # Tailscale --accept-routes; only the firewall FORWARD policy (default
      # DROP) blocks it. Egress-only: return traffic is ESTABLISHED and allowed
      # by conntrack. IPv4 + IPv6 (pod ranges are fd00::/56).
      extraCommands = ''
        iptables -I INPUT -i br+ -j ACCEPT
        iptables -I FORWARD -i br+ -j ACCEPT
        ip6tables -I INPUT -i br+ -j ACCEPT
        ip6tables -I FORWARD -i br+ -j ACCEPT
        iptables -I FORWARD -i cni+ -o tailscale0 -j ACCEPT
        ip6tables -I FORWARD -i cni+ -o tailscale0 -j ACCEPT
      '';
      extraStopCommands = ''
        iptables -D INPUT -i br+ -j ACCEPT 2>/dev/null || true
        iptables -D FORWARD -i br+ -j ACCEPT 2>/dev/null || true
        ip6tables -D INPUT -i br+ -j ACCEPT 2>/dev/null || true
        ip6tables -D FORWARD -i br+ -j ACCEPT 2>/dev/null || true
        iptables -D FORWARD -i cni+ -o tailscale0 -j ACCEPT 2>/dev/null || true
        ip6tables -D FORWARD -i cni+ -o tailscale0 -j ACCEPT 2>/dev/null || true
      '';
    };

    getaddrinfo.precedence = {
      "::1/128" = 50;
      "::/0" = 40;
      "2002::/16" = 30;
      "::/96" = 20;
      "::ffff:0:0/96" = 100;
    };

    wireless = {
      enable = true;
      secretsFile = config.sops.templates.wifi.path;
      networks = {
        "SFR_E368".pskRaw = "ext:psk_sfr_e368";
        "SFR_E368_5SGHZ".pskRaw = "ext:psk_sfr_e368_5ghz";
        "Vintage Korean".pskRaw = "ext:psk_vintage_korean";
      };
    };
  };

  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
      publish = {
        addresses = true;
        enable = true;
        workstation = true;
      };
    };

    knix = {
      # Bridge interface — flannel, firewall, and sysctl rules all target br0.
      # Bonded on Beelink (bond0 → br0), single-NIC on RPi (end0 → br0).
      interface = "br0";

      # Use host-gw for flannel overlay — zero encapsulation overhead on same-LAN clusters
      canal.backend = "host-gw";

      addons.longhorn.enable = true;
    };

    openssh = {
      enable = true;
      openFirewall = true;
    };

    tailscale = {
      authKeyFile = config.sops.secrets.tailscale-authkey.path;
      enable = true;
      extraUpFlags = [
        "--accept-routes"
        "--ssh"
      ];
      openFirewall = true;
      useRoutingFeatures = "server";
      serve.services.syncthing = {
        endpoints."tcp:22000" = "tcp://127.0.0.1:22000";
        advertised = true;
      };
    };

    # Userspace hardware watchdog + system resource monitor
    watchdogd = {
      enable = true;
      settings = {
        meminfo.enabled = true;
        timeout = 120; # Increased from 15s to prevent premature reboots
      };
    };
  };

  sops = {
    secrets = {
      tailscale-authkey.restartUnits = [ "tailscaled.service" ];
      wifi-sfr-e368 = {
        owner = "wpa_supplicant";
        group = "wpa_supplicant";
        restartUnits = [ "wpa_supplicant.service" ];
      };
      wifi-sfr-e368-5ghz = {
        owner = "wpa_supplicant";
        group = "wpa_supplicant";
        restartUnits = [ "wpa_supplicant.service" ];
      };
      wifi-vintage-korean = {
        owner = "wpa_supplicant";
        group = "wpa_supplicant";
        restartUnits = [ "wpa_supplicant.service" ];
      };
    };
    templates.wifi = {
      content = ''
        psk_sfr_e368=${config.sops.placeholder.wifi-sfr-e368}
        psk_sfr_e368_5ghz=${config.sops.placeholder.wifi-sfr-e368-5ghz}
        psk_vintage_korean=${config.sops.placeholder.wifi-vintage-korean}
      '';
      group = "wpa_supplicant";
      mode = "0640";
      restartUnits = [ "wpa_supplicant.service" ];
    };
  };

  systemd.services.tailscale-serve-syncthing = {
    description = "Expose RKE2 and Kubernetes APIs via Tailscale serve with HTTPS";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "5s";
    };
    script = ''
      ${getExe pkgs.tailscale} serve --yes --bg --service=svc:syncthing --http=80 https+insecure://127.0.0.1:443
      ${getExe pkgs.tailscale} serve --yes --bg --service=svc:syncthing --https=443 https+insecure://127.0.0.1:443
    '';
  };

  users.users.nishir = {
    extraGroups = [ "wheel" ];
    home = "/home/nishir";
    initialHashedPassword = "$y$j9T$HB1msXB0DEq00J48zRpB20$/3rhVrTzGrv1j/cPvZ0clOM2gEe1TeylUG39wgD0C42";
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH+tp1Xfz7NomHCZuDPlfj3XW5hm9t0TiCyEeudRraoe"
    ];
  };
}
