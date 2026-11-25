_:

{
  config = {
    networking.firewall.allowedTCPPorts = [
      9119
      9900
      8642
    ];

    networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 9119 ];

    services.cua-driver.enable = true;

    # The agent service runs as this host's operator user's home-manager
    # units. The hermes group keeps its name fleet-wide: one owner string
    # across every host's enc.yaml.
    users.groups.hermes = { };

  };
}
