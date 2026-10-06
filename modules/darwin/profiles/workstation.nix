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
      "ollama"
      "openssl"
      "pinentry-mac"
      "pinentry"
      "pkg-config"
    ];
    casks = [
      "appcleaner"
      "dbeaver-community"
      "deepseek-harness"
      "discord"
      "element"
      "firefox"
      "google-chrome"
      "google-drive"
      "ibkr"
      "jellyfin-media-player"
      "lm-studio"
      "macfuse"
      "mattermost"
      "microsoft-edge"
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

  # Expose A2A (:9900) and LM Studio (:1234) over Tailscale HTTPS.
  # Tailscale is the GUI app on this host, so re-apply the serve config at
  # boot via the GUI CLI; it persists in tailscaled state after first apply.
  # The loop guards the daemon-less boot window: tailscaled may still be
  # starting when launchd runs these at load.
  launchd.daemons.tailscale-serve-a2a = {
    command = ''
      for i in $(seq 1 30); do
        /Applications/Tailscale.app/Contents/MacOS/Tailscale serve --yes --bg --https=9900 http://127.0.0.1:9900 && exit 0
        sleep 10
      done
      echo "tailscale-serve-a2a: tailscaled not ready after 5 minutes" >&2
      exit 1
    '';
    serviceConfig = {
      Label = "org.nixos.tailscale-serve-a2a";
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/var/log/tailscale-serve-a2a.log";
      StandardErrorPath = "/var/log/tailscale-serve-a2a.log";
    };
  };

  launchd.daemons.tailscale-serve-lmstudio = {
    command = ''
      for i in $(seq 1 30); do
        /Applications/Tailscale.app/Contents/MacOS/Tailscale serve --yes --bg --https=1234 http://127.0.0.1:1234 && exit 0
        sleep 10
      done
      echo "tailscale-serve-lmstudio: tailscaled not ready after 5 minutes" >&2
      exit 1
    '';
    serviceConfig = {
      Label = "org.nixos.tailscale-serve-lmstudio";
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/var/log/tailscale-serve-lmstudio.log";
      StandardErrorPath = "/var/log/tailscale-serve-lmstudio.log";
    };
  };
}
