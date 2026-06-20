{ config, ... }:

{
  # Add extra cache
  nix.settings.experimental-features = [
    "flakes"
    "nix-command"
  ];

  nix.extraOptions = ''
    !include ${config.sops.templates.nix-config.path}
  '';

  sops.templates.nix-config.content = ''
    extra-access-tokens = "github.com=${config.sops.placeholder.nix-access-token}"
  '';

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release
  home.stateVersion = "26.05";
}
