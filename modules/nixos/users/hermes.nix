{
  home-manager.users.hermes = {
    home.stateVersion = "26.05";

    programs.git.enable = true;

    # The identities module renders git config from sops templates; the
    # home-manager sops instance decrypts with the node's age key.
    sops.age.keyFile = "/var/lib/sops-nix/key.txt";

    identities = {
      enable = true;
      automata = {
        enable = true;
        git.enable = true;
      };
    };
  };

  users.users.hermes.extraGroups = [
    "adm"
    "systemd-journal"
  ];
}
