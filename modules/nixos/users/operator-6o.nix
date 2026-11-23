{
  users.users.operator-6o = {
    isSystemUser = true;
    group = "hermes";
    home = "/var/lib/hermes";
    createHome = true;
    linger = true;
    # Rootless docker needs /etc/subuid and /etc/subgid entries or
    # dockerd-user hits its start limit (ported from the removed
    # users/hermes.nix).
    subUidRanges = [
      {
        startUid = 196608;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 196608;
        count = 65536;
      }
    ];
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
