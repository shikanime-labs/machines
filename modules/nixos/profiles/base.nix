{ config, ... }:

{
  imports = [ ./minimal.nix ];

  # Colemak at the OS level (TTY + localed -> niri reads it).
  colemak.enable = true;

  # Unicode console font so the bare TTY can actually draw those glyphs
  # (Cyrillic, box-drawing, etc.) instead of tofu blocks.
  console.font = "Lat2-Terminus16";

  # UTF-8 locale so the TTY (and everything else) emits/renders multibyte
  # and special characters instead of falling back to the C locale.
  i18n.defaultLocale = "en_US.UTF-8";

  nix = {
    extraOptions = ''
      !include ${config.sops.templates.nix-config.path}
    '';
    settings = {
      experimental-features = [
        "flakes"
        "nix-command"
      ];
      substituters = [
        "https://cache.nixos.org/"
        "https://cachix.cachix.org"
        "https://devenv.cachix.org"
        "https://shikanime.cachix.org"
        "https://shikanime-studio.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "shikanime.cachix.org-1:OrpjVTH6RzYf2R97IqcTWdLRejF6+XbpFNNZJxKG8Ts="
        "shikanime-studio.cachix.org-1:KxV6aDFU81wzoR9u6pF1uq0dQbUuKbodOSP8/EJHXO0="
      ];
    };
  };

  sops = {
    secrets.nix-github-access-token = {
      sopsFile = ../../../secrets/machine.enc.yaml;
      reloadUnits = [ "nix-daemon.service" ];
    };
    templates.nix-config.content = ''
      extra-access-tokens = github.com=${config.sops.placeholder.nix-github-access-token}
    '';
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html)
  system.stateVersion = "26.05";
}
