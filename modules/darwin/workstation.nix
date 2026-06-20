{ config, ... }:

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

  homebrew = {
    enable = true;
    enableZshIntegration = true;
    brews = [
      "mas"
      "mpv"
      "openssl"
      "pinentry-mac"
      "pinentry"
      "pkg-config"
    ];
    casks = [
      "affinity"
      "android-studio"
      "appcleaner"
      "dbeaver-community"
      "discord"
      "firefox"
      "google-chrome"
      "google-drive"
      "jellyfin-media-player"
      "macfuse"
      "mattermost"
      "microsoft-edge"
      "microsoft-teams"
      "obs"
      "rancher"
      "spotify"
      "syncthing-app"
      "tailscale-app"
      "transmission"
      "windows-app"
      "wireshark-app"
      "xquartz"
      "zen"
      "zoom"
    ];
    masApps = {
      Amphetamine = 937984704;
      Bitwarden = 1352778147;
      Velja = 1607635845;
      Xcode = 497799835;
    };
  };

  nix.linux-builder = {
    enable = true;
    config.boot.binfmt.emulatedSystems = [ "x86_64-linux" ];
    ephemeral = true;
    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };

  programs.zsh.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
