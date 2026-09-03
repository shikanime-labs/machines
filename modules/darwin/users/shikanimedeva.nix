{ config, lib, ... }:

with lib;

let
  toDhall = generators.toDhall { };
in
{
  imports = [
    ../../modules/profiles/ai/home.nix
    ../../modules/profiles/base/home.nix
    ../../modules/apps/cloud/home.nix
    ../../modules/apps/fontconfig/home.nix
    ../../modules/apps/ghostty/home.nix
    ../../modules/apps/helix/home.nix
    ../../modules/apps/starship/home.nix
    ../../modules/apps/vcs/home.nix
    ../../modules/profiles/workstation/home.nix
    ../../modules/apps/zed-editor/home.nix
  ];

  home.sessionVariables.SSH_AUTH_SOCK = "${config.home.homeDirectory}/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock";

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

    automata = {
      enable = true;
      git.condition = "gitpath:${config.home.homeDirectory}/Source/Repos/github.com/yorha-automata";
      jj.extraConfig."--when".repositories = [
        "${config.home.homeDirectory}/Source/Repos/github.com/yorha-automata"
      ];
    };

    shikanime.enable = true;
  };

  programs = {
    bash.enable = true;

    docker-cli = {
      contexts.rancher-desktop = {
        Endpoints = {
          docker = {
            Host = "unix://${config.home.homeDirectory}/.rd/docker.sock";
            SkipTLSVerify = false;
          };
        };
        Metadata.Description = "Rancher Desktop moby context";
      };
      settings = {
        credsStore = "osxkeychain";
        currentContext = "rancher-desktop";
      };
    };

    zsh.enable = true;
  };

  nix.extraOptions = "!include ${config.sops.templates.nix-user-config.path}";

  sops = {
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    defaultSopsFile = ../../../secrets/shikanime.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets.cachix-token = { };
    secrets.github-token = { };
    templates.cachix-config.content = toDhall {
      authToken = config.sops.placeholder.cachix-token;
      hostname = "https://cachix.org";
    };
    templates.nix-user-config.content = ''
      extra-access-tokens = github.com=${config.sops.placeholder.github-token}
    '';
  };

  xdg.configFile."cachix/cachix.dhall".source =
    config.lib.file.mkOutOfStoreSymlink config.sops.templates.cachix-config.path;
}
