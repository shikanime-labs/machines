{
  imports = [
    ./base.nix
  ];

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
      "element"
      "firefox"
      "google-chrome"
      "google-drive"
      "jellyfin-media-player"
      "lm-studio"
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

  programs.zsh.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Expose LM Studio over Tailscale HTTPS (ts.net endpoint on :1234).
  # Tailscale is the GUI app on this host, so re-apply the serve config at
  # boot via the GUI CLI; it persists in tailscaled state after first apply.
  launchd.daemons.tailscale-serve-lmstudio = {
    command = "/Applications/Tailscale.app/Contents/MacOS/Tailscale serve --yes --bg --https=1234 http://127.0.0.1:1234";
    serviceConfig = {
      Label = "org.nixos.tailscale-serve-lmstudio";
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/var/log/tailscale-serve-lmstudio.log";
      StandardErrorPath = "/var/log/tailscale-serve-lmstudio.log";
    };
  };
}
