{
  config,
  modulesPath,
  ...
}:

{
  imports = [
    "${modulesPath}/profiles/headless.nix"
    ../../modules/nixos/base.nix
    ../../modules/nixos/longhorn.nix
    ../../modules/nixos/rke2.nix
  ];

  shikanime.rke2 = {
    enable = true;
    role = "agent";
    serverAddr = "https://nishir:9345";
    tokenSecret = "rke2-token";
    cisHardening = true;
    secretsEncryption = true;
    dualStack = {
      enable = true;
      clusterCIDR = [
        "10.42.0.0/16"
        "fd42:10:42::/56"
      ];
      serviceCIDR = [
        "10.43.0.0/16"
        "fd42:10:43::/112"
      ];
      clusterDNS = [
        "10.43.0.10"
        "fd42:10:43::a"
      ];
    };
  };

  networking.hostName = "fujish";

  nix.extraOptions = ''
    !include ${config.sops.secrets.nix-config.path}
  '';

  services.tailscale = {
    enable = true;
    openFirewall = true;
    authKeyFile = config.sops.secrets.tailscale-authkey.path;
    extraUpFlags = [ "--ssh" ];
    useRoutingFeatures = "server";
  };

  services.openssh = {
    enable = true;
    openFirewall = false;
  };

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ../../secrets/manash.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      rke2-token = {
        sopsFile = ../../secrets/rke2-token.enc.yaml;
      };
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
