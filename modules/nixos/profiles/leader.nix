{
  imports = [ ./machine.nix ];

  services = {
    knix.enable = true;

    # Expose RKE2 API (9345) and Kubernetes API (6443) as a single Tailscale Service.
    # Tailworm serve audit (#1639, F7): the endpoint targets are loopback TCP
    # (kube-apiserver :6443, RKE2 :9345), not unix API sockets, so the F7
    # unix-socket takeover pattern does not apply. Reach is tailnet-only via
    # `tailscale serve`; keep the listeners bound to 127.0.0.1 and never point
    # these endpoints at containerd/cri socket paths.
    tailscale.serve = {
      enable = true;
      services.nishir = {
        advertised = true;
        endpoints = {
          "tcp:6443" = "tcp://127.0.0.1:6443";
          "tcp:9345" = "tcp://127.0.0.1:9345";
        };
      };
    };
  };
}
