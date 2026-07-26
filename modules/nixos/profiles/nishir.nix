{ lib, pkgs, ... }:

with lib;

{
  imports = [
    ./machine.nix
  ];

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
  };

  services = {
    knix = {
      # Bridge interface — flannel, firewall, and sysctl rules all target br0.
      # Bonded on Beelink (bond0 → br0), single-NIC on RPi (end0 → br0).
      interface = "br0";

      # Use host-gw for flannel overlay — zero encapsulation overhead on same-LAN clusters
      canal.backend = "host-gw";
    };

    tailscale.serve.services.syncthing = {
      endpoints."tcp:22000" = "tcp://127.0.0.1:22000";
      advertised = true;
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
}
