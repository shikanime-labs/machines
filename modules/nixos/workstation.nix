{ config, pkgs, ... }:

{
  nix.extraOptions = ''
    !include ${config.sops.templates.nix-config.path}
  '';

  sops = {
    secrets.nix-access-token = { };
    templates.nix-config.content = ''
      extra-access-tokens = "github.com=${config.sops.placeholder.nix-access-token}"
    '';
  };

  programs.gnupg.agent = {
    enable = true;
    enableExtraSocket = true;
    pinentryPackage = pkgs.pinentry-all;
    settings.default-cache-ttl = 60 * 60;
  };
}
