{ config, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-base.nix"
    "${modulesPath}/profiles/headless.nix"
    ../../modules/nixos/base.nix
    ../../modules/nixos/longhorn.nix
  ];

  home-manager.users.nishir.imports = [
    ./users/nishir/home-configuration.nix
  ];

  nix.extraOptions = ''
    !include ${config.sops.secrets.nix-config.path}
  '';

  networking.hostName = "minish";

  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };

    tailscale = {
      enable = true;
      openFirewall = true;
      authKeyFile = config.sops.secrets.tailscale-authkey.path;
      extraUpFlags = [ "--ssh" ];
      useRoutingFeatures = "server";
    };

    openssh = {
      enable = true;
      openFirewall = true;
    };
  };

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ../../secrets/minish.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      tailscale-authkey = { };
      nix-config = { };
    };
  };

  users.users.nishir = {
    extraGroups = [ "wheel" ];
    initialHashedPassword = "$y$j9T$HB1msXB0DEq00J48zRpB20$/3rhVrTzGrv1j/cPvZ0clOM2gEe1TeylUG39wgD0C42";
    isNormalUser = true;
    home = "/home/nishir";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH+tp1Xfz7NomHCZuDPlfj3XW5hm9t0TiCyEeudRraoe"
    ];
  };
}
