{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  # Darwin hosts run hermes as the user, so the A2A env comes from the user
  # session instead of a systemd environmentFile. Mirrors ai.nix (NixOS).
  a2aPeers = [
    "ashira"
    "fushi"
    "ishtar"
    "manash"
    "minish"
    "nalsha"
    "nemishi"
    "nixtar"
    "telsha"
  ];
  a2aSelf = osConfig.networking.hostName;
  a2aOtherPeers = builtins.filter (p: p != a2aSelf) a2aPeers;
  mkA2aPeerToken = peer: "${peer}:${config.sops.placeholder."hermes-agent-a2a-token-${peer}"}";
in
{
  home = {
    packages = with pkgs; [
      qwen-code
      rtk
    ];

    sessionVariables = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      A2A_HOST = "0.0.0.0";
      A2A_PORT = "9900";
      A2A_AGENT_NAME = a2aSelf;
      A2A_PUBLIC_URL = "https://${a2aSelf}.taila659a.ts.net:9900";
      A2A_OWN_TOKEN = config.sops.placeholder."hermes-agent-a2a-token-${a2aSelf}";
      A2A_PEER_TOKENS = lib.concatStringsSep "," (map mkA2aPeerToken a2aOtherPeers);
      A2A_TRUSTED_PEERS = lib.concatStringsSep "," a2aOtherPeers;
    };
  };

  programs = {
    antigravity-cli.enable = true;

    codex.enable = true;

    claude-code.enable = true;
  };

  sops.secrets = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
    builtins.listToAttrs (
      map (
        peer:
        lib.nameValuePair "hermes-agent-a2a-token-${peer}" {
          sopsFile = ../../secrets/machine.enc.yaml;
          owner = config.home.username;
        }
      ) a2aPeers
    )
  );
}
