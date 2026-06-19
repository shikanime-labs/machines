{ modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    "${modulesPath}/profiles/headless.nix"
    ../../modules/nixos/base.nix
    ../../modules/nixos/telashi.nix
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

  home-manager.users.nishir.imports = [
    ./users/nishir/home-configuration.nix
  ];

  networking = {
    hostName = "nemishi";
  };

  shikanime.rke2.extraConfig.nodeIP = "192.168.1.27";

  sops = {
    defaultSopsFile = ../../secrets/nemishi.enc.yaml;
    defaultSopsFormat = "yaml";
  };

  systemd.tmpfiles.rules = [
    "L+ /var/lib/rancher/rke2 - - - - /mnt/nishir/rke2"
    "L+ /var/lib/longhorn - - - - /mnt/nishir/longhorn"
    "L+ /var/log/calico - - - - /mnt/nishir/log/calico"
    "L+ /var/log/containers - - - - /mnt/nishir/log/containers"
    "L+ /var/log/pods - - - - /mnt/nishir/log/pods"
    "L+ /var/swap - - - - /mnt/nishir/swap"
  ];
}
