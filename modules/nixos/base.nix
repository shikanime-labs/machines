{ config, ... }:

{
  imports = [
    ./minimal.nix
  ];

  nix.extraOptions = ''
    !include ${config.sops.templates.nix-config.path}
  '';

  sops = {
    secrets.nix-access-token.reloadUnits = [ "nix-daemon.service" ];
    secrets.comin-discord-webhook = {
      sopsFile = ../../secrets/${config.networking.hostName}.enc.yaml;
      mode = "0400";
    };
    templates.nix-config.content = ''
      extra-access-tokens = "github.com=${config.sops.placeholder.nix-access-token}"
    '';
  };

  services.comin = {
    enable = true;
    remotes = [
      {
        name = "origin";
        url = "https://github.com/shikanime/shikanime.git";
      }
    ];

    exporter = {
      listenAddress = "";
      port = 4243;
      openFirewall = false;
    };

    postDeploymentCommand = pkgs.writeShellScript "comin-discord-notify" ''
      set -euo pipefail

      WEBHOOK_FILE="${config.sops.secrets.comin-discord-webhook.path}"

      if [ ! -f "$WEBHOOK_FILE" ]; then
        echo "comin-discord: webhook secret not found, skipping" >&2
        exit 0
      fi

      WEBHOOK_URL=$(cat "$WEBHOOK_FILE")
      HOSTNAME="''${COMIN_HOSTNAME:-$(hostname -s)}"
      SHA="''${COMIN_GIT_SHA:-unknown}"
      REF="''${COMIN_GIT_REF:-unknown}"
      MSG="''${COMIN_GIT_MSG:-unknown}"
      STATUS="''${COMIN_STATUS:-unknown}"
      SHORT_SHA=''${SHA:0:8}

      # Color: green=success(3066993), red=error(15158332)
      COLOR=3066993
      if [ "$STATUS" = "error" ]; then
        COLOR=15158332
      fi

      # Truncate commit message to first line, max 120 chars
      MSG=$(echo "$MSG" | head -n1)
      if [ ''${#MSG} -gt 120 ]; then
        MSG="''${MSG:0:117}..."
      fi

      TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

      printf -v PAYLOAD '%s' '{
        "embeds": [{
          "title": "'"''$HOSTNAME"'": Deployed",
          "description": "[`'"''$SHORT_SHA"'`] ('"''$REF"') '"''$MSG"'",
          "color": '"''$COLOR"',
          "timestamp": "''$TIMESTAMP"
        }]
      }'

      curl -fsS -o /dev/null \
        -H "Content-Type: application/json" \
        -d "$PAYLOAD" \
        "$WEBHOOK_URL" || true
    '';
  };
  system.stateVersion = "26.05";
}
