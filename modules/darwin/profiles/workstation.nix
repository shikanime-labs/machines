let
  # Tailworm serve audit (#1639, F7): these launchd daemons forward tailnet-only
  # HTTPS ports to loopback HTTP ports (a2a :9900, lmstudio :1234) on this macOS
  # workstation. Targets are loopback TCP, not unix API sockets, so the F7
  # socket-takeover pattern does not apply; the sockets listen on 127.0.0.1 only
  # and `tailscale serve` grants access to tailnet identities, not the public
  # internet (no funnel here). Keep ports loopback-bound; never forward socket
  # or file targets.
  mkTailscaleServe = name: port: {
    command = "/Applications/Tailscale.app/Contents/MacOS/Tailscale serve --yes --bg --https=${toString port} http://127.0.0.1:${toString port}";
    serviceConfig = {
      KeepAlive.SuccessfulExit = false;
      Label = "org.nixos.tailscale-serve-${name}";
      RunAtLoad = true;
      StandardErrorPath = "/var/log/tailscale-serve-${name}.log";
      StandardOutPath = "/var/log/tailscale-serve-${name}.log";
    };
  };
in
{
  imports = [ ./base.nix ];

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

  programs = {
    zsh.enable = true;

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  launchd.daemons = {
    tailscale-serve-a2a = mkTailscaleServe "a2a" 9900;
    tailscale-serve-lmstudio = mkTailscaleServe "lmstudio" 1234;
  };
}
