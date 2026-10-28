{
  imports = [
    ../../modules/nixos/profiles/agent.nix
    ../../modules/nixos/profiles/nishir.nix
    ../../modules/nixos/hardware/minisforum-ms-s1.nix
    ../../modules/nixos/users/operator-20o.nix
  ];

  networking = {
    hostName = "kushira";
    defaultGateway = {
      address = "192.168.1.1";
      interface = "br0";
    };
    interfaces.br0.ipv4.addresses = [
      {
        address = "192.168.1.91";
        prefixLength = 24;
      }
    ];
  };

  systemd.network.networks."40-br1".address = [ "10.66.0.2/29" ];

  services = {
    knix = {
      nodeIP = "192.168.1.91,2a02:8424:7899:f201:94eb:8d1:325a:c6e9";
      labels = {
        "beta.kubernetes.io/instance-type" = "minisforum-ms-s1";
        "node.kubernetes.io/instance-type" = "minisforum-ms-s1";
      };
    };

  };

  sops = {
    defaultSopsFile = ../../secrets/kushira.enc.yaml;
    defaultSopsFormat = "yaml";
  };

  system.stateVersion = "26.05";
}
