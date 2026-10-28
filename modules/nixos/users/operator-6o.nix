{
  users.users.operator-6o = {
    isSystemUser = true;
    group = "hermes";
    home = "/var/lib/hermes";
    createHome = true;
    linger = true;
    extraGroups = [
      "adm"
      "systemd-journal"
    ];
  };

  home-manager.users.operator-6o.imports = [
    ../../home/hermes-agent.nix
    ../../home/hermes-agent-automata.nix
  ];
}
