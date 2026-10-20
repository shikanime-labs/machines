{
  imports = [ ../users/automata.nix ];

  home-manager.users.hermes.imports = [ ../../home/hermes.nix ];
}
