{
  imports = [ ./machine.nix ];

  services = {
    knix.enable = true;

    # Expose RKE2 API (9345) and Kubernetes API (6443) as a single Tailscale Service.
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
