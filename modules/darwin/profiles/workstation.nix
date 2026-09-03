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
      "ibkr"
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

  # A2A agent mesh (telsha). The Hermes agent serves plain HTTP on :9900 and
  # the api_server on :8642; Tailscale serve terminates TLS and forwards to
  # localhost, so peers reach https://telsha.taila659a.ts.net:9900. Advertise
  # the automata + workstation tags so the tailnet ACL grants/deny backstop
  # cover this host. Idempotent; re-applied at boot.
  launchd.daemons.tailscale-up-a2a = {
    command = "/Applications/Tailscale.app/Contents/MacOS/Tailscale up --advertise-tags=tag:automata,tag:workstation";
    serviceConfig = {
      Label = "org.nixos.tailscale-up-a2a";
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/var/log/tailscale-up-a2a.log";
      StandardErrorPath = "/var/log/tailscale-up-a2a.log";
    };
  };

  launchd.daemons.tailscale-serve-a2a = {
    command = "/Applications/Tailscale.app/Contents/MacOS/Tailscale serve --yes --bg --https=9900 http://127.0.0.1:9900";
    serviceConfig = {
      Label = "org.nixos.tailscale-serve-a2a";
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/var/log/tailscale-serve-a2a.log";
      StandardErrorPath = "/var/log/tailscale-serve-a2a.log";
    };
  };

  launchd.daemons.tailscale-serve-api = {
    command = "/Applications/Tailscale.app/Contents/MacOS/Tailscale serve --yes --bg --https=8642 http://127.0.0.1:8642";
    serviceConfig = {
      Label = "org.nixos.tailscale-serve-api";
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "/var/log/tailscale-serve-api.log";
      StandardErrorPath = "/var/log/tailscale-serve-api.log";
    };
  };
}
