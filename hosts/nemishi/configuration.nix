{ modulesPath, ... }:

{
  imports = [
    ../../modules/nixos/profiles/agent.nix
    ../../modules/nixos/profiles/nishir.nix
    ../../modules/nixos/hardware/rpi5.nix
    ../../modules/nixos/users/operator-18o.nix
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];

  disko.devices.disk.data = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = {
      type = "filesystem";
      format = "xfs";
      mountpoint = "/mnt/data";
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
    hostName = "nemishi";
    defaultGateway = {
      address = "192.168.1.1";
      interface = "br0";
    };
    interfaces.br0.ipv4.addresses = [
      {
        address = "192.168.1.27";
        prefixLength = 24;
      }
    ];
  };

  services = {

    knix = {
      nodeIP = "192.168.1.27,2a02:8424:7899:f201:94eb:8d1:325a:aa5b";
      labels = {
        "beta.kubernetes.io/instance-type" = "rpi5";
        "node.kubernetes.io/instance-type" = "rpi5";
      };
    };
  };

  sops = {
    defaultSopsFile = ../../secrets/nemishi.enc.yaml;
    defaultSopsFormat = "yaml";
  };
}
