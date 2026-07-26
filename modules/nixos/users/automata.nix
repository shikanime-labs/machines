{
  users.users.automata = {
    initialHashedPassword = "";
    isNormalUser = true;
    home = "/home/automata";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOuenA6cT5pkPEwdGvmvXRjVqFTv2QwpyYrB7gvMy0/X"
    ];
  };

  home-manager.users.automata = {
    imports = [
      ../../../modules/home/base.nix
      ../../../modules/home/cloud.nix
      ../../../modules/home/vcs.nix
      ../../../modules/home/workstation.nix
    ];
    programs.bash.enable = true;
  };
}
