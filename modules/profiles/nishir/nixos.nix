{ lib, pkgs, ... }:

with lib;

{
  imports = [
    ../machine/nixos.nix
    ../wifi/nixos.nix
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
        iptables -I FORWARD -i cni+ -o tailscale0 -j ACCEPT
        ip6tables -I FORWARD -i cni+ -o tailscale0 -j ACCEPT
      '';
      extraStopCommands = ''
        iptables -D INPUT -i br+ -j ACCEPT 2>/dev/null || true
        ip6tables -D INPUT -i br+ -j ACCEPT 2>/dev/null || true
        iptables -D FORWARD -i br+ -j ACCEPT 2>/dev/null || true
        ip6tables -D FORWARD -i br+ -j ACCEPT 2>/dev/null || true
        iptables -D FORWARD -i cni+ -o tailscale0 -j ACCEPT 2>/dev/null || true
        ip6tables -D FORWARD -i cni+ -o tailscale0 -j ACCEPT 2>/dev/null || true
      '';
    };

    # Pod -> tailnet egress. Under flannel host-gw, pod traffic reaches the
    # host on br0 with source 10.244.0.0/16. Tailscale installs its peer/CGNAT
    # routes in table 52, but the main table has no route to 100.64.0.0/10, so
    # pod-bound tailnet packets fall through to the LAN bridge (br0) and die.
    # The policy route sends pod-source traffic to table 52 (taking the
    # tailscale0 route). Split from firewall.service because ip rule needs
    # iproute2 (not in the firewall unit's restricted PATH) and tailnet
    # routes must exist before the rule is installed.
    nat = {
      enable = true;
      enableIPv6 = true;
      externalInterface = "tailscale0";
      internalIPs = [ "10.244.0.0/16" ];
      internalIPv6s = [ "fd00::/16" ];
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
      # Bonded on Beelink (bond0 -> br0), single-NIC on RPi (end0 -> br0).
      interface = "br0";

      # Use host-gw for flannel overlay — zero encapsulation overhead on same-LAN clusters
      canal.backend = "host-gw";
    };

  };

  systemd.services.cluster-policy-route = {
    description = "Policy route: pod-source -> Tailscale routing table 52";
    wants = [ "tailscaled.service" ];
    after = [
      "tailscaled.service"
      "networking-ready.target"
    ];
    wantedBy = [ "multi-user.target" ];
    # iprule needs iproute2; the policy route must be installed after Tailscale
    # populates table 52 with peer/CGNAT routes.
    path = [ pkgs.iproute2 ];
    script = ''
      ip rule add from 10.244.0.0/16 lookup 52 prio 5000
    '';
    preStop = ''
      ip rule del from 10.244.0.0/16 lookup 52 prio 5000 2>/dev/null || true
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
}
