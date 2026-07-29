{
  home-manager.users.meika = {
    imports = [
      ../../../modules/home/base.nix
      ../../../modules/home/graphical.nix
      ../../../modules/home/ghostty.nix
      ../../../modules/home/starship.nix
      ../../../modules/home/workstation.nix
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
