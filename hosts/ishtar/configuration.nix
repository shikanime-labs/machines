{ config, ... }:

{
  imports = [
    ../../modules/nixos/razer-blade.nix
  ];

  # Windows dual-boot: mount Windows partition read-only
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-uuid/2E33-B8AC";
      fsType = "vfat";
    };
    "/" = {
      device = "/dev/disk/by-uuid/89923803-6c1a-48f4-953d-429803cc46a5";
      fsType = "ext4";
    };
  };

  networking.hostName = "ishtar";

  services = {
    openssh = {
      enable = true;
      openFirewall = true;
    };

    tailscale = {
      enable = true;
      openFirewall = true;
      authKeyFile = config.sops.secrets.tailscale-authkey.path;
      extraUpFlags = [
        "--accept-routes"
        "--ssh"
      ];
    };
  };

  home-manager.users.shika.imports = [
    ./users/shika/home-configuration.nix
  ];

  sops = {
    age = {
      generateKey = true;
      keyFile = "/var/lib/sops-nix/key.txt";
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
    defaultSopsFile = ../../secrets/ishtar.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      wifi-sfr-e368.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-sfr-e368-5ghz.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-vintage-korean.sopsFile = ../../secrets/nishir.enc.yaml;
    };
  };

  users.users.shika = {
    extraGroups = [
      "wheel"
      "plugdev"
    ];
    home = "/home/shika";
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH+tp1Xfz7NomHCZuDPlfj3XW5hm9t0TiCyEeudRraoe"
    ];
  };

  system.stateVersion = "26.05";
}
