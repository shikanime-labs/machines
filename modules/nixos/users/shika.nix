{ lib, ... }:

with lib;

let
  toDhall = generators.toDhall { };
in
{
  home-manager.users.shika = { config, ... }: {
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

    home.sessionVariables.SSH_AUTH_SOCK = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";

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

    programs.bash.enable = true;

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
  };

  users.users.shika = {
    extraGroups = [
      "audio"
      "hermes"
      "plugdev"
      "video"
      "wheel"
    ];
    home = "/home/shika";
    initialHashedPassword = "$y$j9T$3nIVNUGT/i3/bS3kiaDC7.$KgHv3Ld.O989KuqPTkJlSHq4Uq47eLVES6mL2Vlo324";
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH+tp1Xfz7NomHCZuDPlfj3XW5hm9t0TiCyEeudRraoe"
    ];
  };
}
