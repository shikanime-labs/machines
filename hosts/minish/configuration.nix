{ modulesPath, ... }:

{
  imports = [
    ../../modules/nixos/profiles/agent.nix
    ../../modules/nixos/profiles/nishir.nix
    ../../modules/nixos/hardware/rpi4.nix
    ../../modules/nixos/users/operator-16o.nix
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];

  disko.devices.disk.reimu = {
    type = "disk";
    device = "/dev/disk/by-label/reimu";
    content = {
      type = "filesystem";
      format = "xfs";
      mountpoint = "/mnt/reimu";
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
    hostName = "minish";
    defaultGateway = {
      address = "192.168.1.1";
      interface = "br0";
    };
    interfaces.br0.ipv4.addresses = [
      {
        address = "192.168.1.77";
        prefixLength = 24;
      }
    ];
  };

  services = {

    knix = {
      nodeIP = "192.168.1.77,fd7a:115c:a1e0::bb3a:b57";
      labels = {
        "beta.kubernetes.io/instance-type" = "rpi4-model-b";
        "node.kubernetes.io/instance-type" = "rpi4-model-b";
      };
    };
  };

  sops = {
    defaultSopsFile = ../../secrets/minish.enc.yaml;
    defaultSopsFormat = "yaml";
  };
}
