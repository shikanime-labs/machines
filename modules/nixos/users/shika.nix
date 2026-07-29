{ config, lib, ... }:

with lib;

let
  toDhall = generators.toDhall { };
in
{
  imports = [
    ../../../modules/home/ai.nix
    ../../../modules/home/base.nix
    ../../../modules/home/cloud.nix
    ../../../modules/home/fontconfig.nix
    ../../../modules/home/ghostty.nix
    ../../../modules/home/graphical.nix
    ../../../modules/home/helix.nix
    ../../../modules/home/starship.nix
    ../../../modules/home/vcs.nix
    ../../../modules/home/workstation.nix
    ../../../modules/home/zed-editor.nix
  ];

  # Bitwarden binds its SSH agent socket to BITWARDEN_SSH_AUTH_SOCK (falls back
  # to $HOME/.bitwarden-ssh-agent.sock). Point both it and SSH_AUTH_SOCK at the
  # XDG runtime dir so the socket lives under /run/user/$UID, not $HOME root.
  home.sessionVariables =
    let
      bitwardenSshAuthSock = "${config.xdg.configHome}/.bitwarden-ssh-agent.sock";
    in
    {
      BITWARDEN_SSH_AUTH_SOCK = bitwardenSshAuthSock;
      SSH_AUTH_SOCK = bitwardenSshAuthSock;
    };

  identities = {
    enable = true;

    ghstack.enable = true;

    glab.enable = true;

    gouv = {
      enable = true;
      git.condition = "gitpath:${config.home.homeDirectory}/Source/Repos/github.com/cloud-pi-native";
      jj.extraConfig."--when".repositories = [
        "${config.home.homeDirectory}/Source/Repos/github.com/cloud-pi-native"
      ];
    };

    operator-6o = {
      enable = true;
      git.condition = "gitpath:${config.home.homeDirectory}/Source/Repos/github.com/operator6o";
      jj.extraConfig."--when".repositories = [
        "${config.home.homeDirectory}/Source/Repos/github.com/operator6o"
      ];
    };

    shikanime.enable = true;
  };

  programs.bash.enable = true;

  sops = {
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    defaultSopsFile = ../../../secrets/shikanime.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets.cachix-token = { };
    templates.cachix-config.content = toDhall {
      authToken = config.sops.placeholder.cachix-token;
      hostname = "https://cachix.org";
    };
  };

  xdg.configFile."cachix/cachix.dhall".source =
    config.lib.file.mkOutOfStoreSymlink config.sops.templates.cachix-config.path;
}
