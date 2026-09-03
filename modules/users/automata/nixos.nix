{
  home-manager.users.automata = {
    imports = [
      ../../profiles/base/home.nix
      ../../apps/cloud/home.nix
      ../../apps/vcs/home.nix
      ../../profiles/workstation/home.nix
    ];
    programs.bash.enable = true;
  };

  users.users.automata = {
    initialHashedPassword = "";
    isNormalUser = true;
    home = "/home/automata";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOuenA6cT5pkPEwdGvmvXRjVqFTv2QwpyYrB7gvMy0/X"
    ];
  };
}
