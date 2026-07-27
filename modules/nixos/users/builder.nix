{ pkgs, lib, ... }:

let
  builderSshKeyFile = config.sops.secrets.builder-ssh-key.path;
in {
  imports = [ ../server.nix ];

  sops.secrets.builder-ssh-key = {
    restartUnits = [ "sshd.service" ];
    format = "binary";
  };

  users.users.builder = {
    isNormalUser = true;
    home = "/home/builder";
    openssh.authorizedKeys.keys = [
      (lib.readFile builderSshKeyFile)
    ];
    useDefaultShell = true;
  };
}
