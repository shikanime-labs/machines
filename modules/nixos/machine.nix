{ config, ... }:

{
  imports = [
    ./base.nix
    ./wifi.nix
  ];

  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
      publish = {
        addresses = true;
        enable = true;
        workstation = true;
      };
    };

    openssh = {
      enable = true;
      openFirewall = true;
    };

    tailscale = {
      authKeyFile = config.sops.secrets.tailscale-authkey.path;
      enable = true;
      extraUpFlags = [
        "--accept-routes"
        "--ssh"
      ];
      openFirewall = true;
      useRoutingFeatures = "server";
    };
  };

  sops.secrets.tailscale-authkey.restartUnits = [ "tailscaled.service" ];
}
