{
  imports = [
    ../../modules/nixos/profiles/leader.nix
    ../../modules/nixos/profiles/nishir.nix
    ../../modules/nixos/hardware/beelink-eq.nix
    ../../modules/nixos/users/operator-8o.nix
  ];

  disko.devices.disk.flandre = {
    type = "disk";
    device = "/dev/disk/by-label/flandre";
    content = {
      type = "filesystem";
      format = "xfs";
      mountpoint = "/mnt/flandre";
      mountOptions = [
        "nofail"
        "x-systemd.automount"
        "x-systemd.device-timeout=10s"
        "x-systemd.mount-timeout=30s"
      ];
    };
  };

  hardware.facter.reportPath = ./facter.json;

  networking = {
    hostName = "manash";
    defaultGateway = {
      address = "192.168.1.1";
      interface = "br0";
    };
    interfaces.br0.ipv4.addresses = [
      {
        address = "192.168.1.28";
        prefixLength = 24;
      }
    ];
  };

  services = {

    knix = {
      nodeIP = "192.168.1.28,2a02:8424:7899:f201:94eb:8d1:325a:7181";
      labels = {
        "beta.kubernetes.io/instance-type" = "beelink-eq14";
        "node.kubernetes.io/instance-type" = "beelink-eq14";
      };
    };
  };

  sops = {
    defaultSopsFile = ../../secrets/manash.enc.yaml;
    defaultSopsFormat = "yaml";
  };
}
