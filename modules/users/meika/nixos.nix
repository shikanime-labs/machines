{
  home-manager.users.meika = {
    imports = [
      ../../profiles/base/home.nix
      ../../profiles/graphical/home.nix
      ../../apps/ghostty/home.nix
      ../../apps/starship/home.nix
      ../../profiles/workstation/home.nix
    ];
  };

  users.users.meika = {
    extraGroups = [
      "audio"
      "video"
    ];
    home = "/home/meika";
    initialHashedPassword = "$y$j9T$3nIVNUGT/i3/bS3kiaDC7.$KgHv3Ld.O989KuqPTkJlSHq4Uq47eLVES6mL2Vlo324";
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH+tp1Xfz7NomHCZuDPlfj3XW5hm9t0TiCyEeudRraoe"
    ];
  };
}
