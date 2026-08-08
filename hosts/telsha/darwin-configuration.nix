{
  imports = [
    ../../modules/darwin/profiles/ai.nix
    ../../modules/darwin/profiles/distributed.nix
    ../../modules/darwin/profiles/workstation.nix
  ];

  home-manager.users.shikanimedeva.imports = [
    ../../modules/darwin/users/shikanimedeva.nix
  ];

  networking.hostName = "telsha";

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = ../../secrets/telsha.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets.nix-access-token.sopsFile = ../../secrets/machine.enc.yaml;
  };

  system.primaryUser = "shikanimedeva";

  users.users.shikanimedeva = {
    home = "/Users/shikanimedeva";
    name = "shikanimedeva";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH+tp1Xfz7NomHCZuDPlfj3XW5hm9t0TiCyEeudRraoe"
    ];
  };
}
