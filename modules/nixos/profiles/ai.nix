{ config, lib, ... }:

with lib;

let
  topology = import ../../home/hermes-topology.nix { inherit lib; };
  libH = import ../../lib/hermes.nix { inherit lib; };
  operator = "operator-${config.networking.hostName}";



  inherit (topology) peers;
in
{
  config = {

    networking.firewall.allowedTCPPorts = [
      9119
      9900
      8642
    ];

    networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 9119 ];

    services.cua-driver.enable = true;

    # System-level sops keeps ONLY the peer tokens the firewall/ssh side of the
    # fleet shared via machine.enc.yaml — and even those are operator-owned so
    # the user units can read them. Everything else (matrix, providers,
    # desktop, a2a env) decrypts in the operator's home-manager scope.
    sops.secrets = {
      hermes-agent-desktop-token = {
        sopsFile = ../../../secrets/machine.enc.yaml;
        group = "hermes";
        owner = operator;
      };
    }
    // (libH.mkA2aTokenSecrets { sopsFile = ../../../secrets/machine.enc.yaml; group = "hermes"; owner = operator; } peers)
    // (libH.mkPeerApiServerKeySecrets { sopsFile = ../../../secrets/machine.enc.yaml; group = "hermes"; owner = operator; } peers);

    # The agent service runs as this host's operator user's home-manager
    # units. The hermes group keeps its name fleet-wide: one owner string
    # across every host's enc.yaml.
    users.groups.hermes = { };

  };
}
