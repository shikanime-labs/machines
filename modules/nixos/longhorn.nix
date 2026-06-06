{ config, pkgs, ... }:

{
  # Enable iscsi protocol support at kernel level
  boot.kernelModules = [
    "dm_crypt"
    "iscsi_tcp"
  ];

  services.openiscsi = {
    enable = true;
    name = "iqn.2026-06.io.shikanime:${config.networking.hostName}";
  };

  # Enable NFS support at kernel level
  boot.supportedFilesystems = [ "nfs" ];

  environment.systemPackages = with pkgs; [
    cryptsetup
    lvm2
    nfs-utils
    openiscsi
  ];

  # FIXME: https://github.com/longhorn/longhorn/issues/2166
  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
  ];
}
