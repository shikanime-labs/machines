{ modulesPath, ... }:

{
  imports = [
    ../../modules/nixos/profiles/agent.nix
    ../../modules/nixos/profiles/nishir.nix
    ../../modules/nixos/hardware/rpi4.nix
    ../../modules/nixos/users/operator-14o.nix
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];

  disko.devices.disk.marisa = {
    type = "disk";
    device = "/dev/disk/by-label/marisa";
    content = {
      type = "filesystem";
      format = "xfs";
      mountpoint = "/mnt/marisa";
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
    hostName = "fushi";
    defaultGateway = {
      address = "192.168.1.1";
      interface = "br0";
    };
    interfaces.br0.ipv4.addresses = [
      {
        address = "192.168.1.80";
        prefixLength = 24;
      }
    ];
  };

  services = {

    knix = {
      nodeIP = "192.168.1.80,fd7a:115c:a1e0::793a:a25d";
      labels = {
        "beta.kubernetes.io/instance-type" = "rpi4-model-b";
        "node.kubernetes.io/instance-type" = "rpi4-model-b";
      };
    };
  };

  sops = {
    defaultSopsFile = ../../secrets/fushi.enc.yaml;
    defaultSopsFormat = "yaml";
  };
}
