{ lib, pkgs, ... }:

with lib;

{
  imports = [
    ./machine.nix
    ./wifi.nix
  ];

  networking = {
    interfaces.br0.wakeOnLan.enable = true;

    firewall = {
      # Cluster -> tailnet egress. Pods route via the node (flannel host-gw),
      # so their traffic reaches the host on the CNI bridge (cni0) and is
      # forwarded out tailscale0 to tailnet CGNAT addresses (100.64.0.0/10,
      # e.g. *.ts.net). The node holds these routes via Tailscale
      # --accept-routes; the FORWARD ACCEPT lifts the default DROP for the
      # forward leg.
      extraCommands = ''
        iptables -I INPUT -i br+ -j ACCEPT
        iptables -I FORWARD -i br+ -j ACCEPT
        ip6tables -I INPUT -i br+ -j ACCEPT
        ip6tables -I FORWARD -i br+ -j ACCEPT
        iptables -I FORWARD -i cni+ -o tailscale0 -j ACCEPT
        ip6tables -I FORWARD -i cni+ -o tailscale0 -j ACCEPT
        iptables -t nat -I POSTROUTING -o tailscale0 -s 10.244.0.0/16 -m conntrack --ctstate NEW -j MASQUERADE
        ip6tables -t nat -I POSTROUTING -o tailscale0 -s fd00::/16 -m conntrack --ctstate NEW -j MASQUERADE
      '';
      extraStopCommands = ''
        iptables -D INPUT -i br+ -j ACCEPT 2>/dev/null || true
        iptables -D FORWARD -i br+ -j ACCEPT 2>/dev/null || true
        ip6tables -D INPUT -i br+ -j ACCEPT 2>/dev/null || true
        ip6tables -D FORWARD -i br+ -j ACCEPT 2>/dev/null || true
        iptables -D FORWARD -i cni+ -o tailscale0 -j ACCEPT 2>/dev/null || true
        ip6tables -D FORWARD -i cni+ -o tailscale0 -j ACCEPT 2>/dev/null || true
        iptables -t nat -D POSTROUTING -o tailscale0 -s 10.244.0.0/16 -m conntrack --ctstate NEW -j MASQUERADE 2>/dev/null || true
        ip6tables -t nat -D POSTROUTING -o tailscale0 -s fd00::/16 -m conntrack --ctstate NEW -j MASQUERADE 2>/dev/null || true
      '';
    };
  };

  services = {
    knix = {
      addons.flux.instance.extraConfig.instance.sync = {
        interval = "1m";
        kind = "GitRepository";
        path = "clusters/nishir/overlays/tailnet";
        ref = "refs/heads/main";
        url = "https://github.com/shikanime-labs/manifests.git";
      };

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
    description = "Expose RKE2 and Kubernetes APIs via Tailscale serve";
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
      ${getExe pkgs.tailscale} serve --yes --bg --service=svc:syncthing --http=80 https+insecure://127.0.0.1:443
    '';
  };
}
