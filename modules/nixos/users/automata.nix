{
  config,
  lib,
  pkgs,
  ...
}:

let
  ai = import ../../lib/ai.nix { inherit lib; };

  hermesOwned = lib.mapAttrs (
    _: v:
    v
    // {
      group = "hermes";
      owner = "hermes";
    }
  );
in
{
  users.groups.hermes = { };

  users.users.hermes = {
    createHome = true;
    extraGroups = [
      "adm"
      "systemd-journal"
    ];
    group = "hermes";
    home = "/var/lib/hermes";
    isSystemUser = true;
    linger = true;
    shell = pkgs.bashInteractive;
  };

  networking.firewall = {
    allowedTCPPorts = [
      9119
      9900
      8642
    ];
    interfaces."tailscale0".allowedTCPPorts = [ 9119 ];
  };

  services.cua-driver.enable = true;

  sops = {
    secrets = {
      hermes-agent-desktop-token.sopsFile = ../../../secrets/machine.enc.yaml;
      hermes-agent-matrix-access-token = { };
      hermes-agent-matrix-recovery-key.mode = "0600";
      hermes-agent-sks-api-key.sopsFile = ../../../secrets/machine.enc.yaml;
      hermes-agent-github-token.sopsFile = ../../../secrets/machine.enc.yaml;
    }
    // hermesOwned (ai.mkA2aTokenSecrets ../../../secrets/machine.enc.yaml ai.peers)
    // hermesOwned (ai.mkPeerApiServerKeySecrets ../../../secrets/machine.enc.yaml ai.peers);

    templates = {
      hermes-agent-env.content = ''
        API_SERVER_ENABLED=true
        API_SERVER_KEY=${config.sops.placeholder."${ai.mkPeerApiServerKeyName config.networking.hostName}"}
      '';
      hermes-agent-peer-keys-env.content = toString (
        ai.mkPeerKeyEnvs config.sops.placeholder (
          ai.mkSelfExcludedPeers config.networking.hostName ai.peers
        )
      );
      hermes-agent-matrix-env.content = ''
        MATRIX_HOMESERVER=https://matrix.taila659a.ts.net/
        MATRIX_ACCESS_TOKEN=${config.sops.placeholder.hermes-agent-matrix-access-token}
        MATRIX_DEVICE_ID=AUTOMATA6O
        MATRIX_E2EE_MODE=required
        MATRIX_HOME_ROOM=#automata:matrix.taila659a.ts.net
        MATRIX_RECOVERY_KEY=${config.sops.placeholder.hermes-agent-matrix-recovery-key}
      '';
      hermes-agent-providers-env.content = ''
        SKS_API_KEY=${config.sops.placeholder.hermes-agent-sks-api-key}
        GITHUB_TOKEN=${config.sops.placeholder.hermes-agent-github-token}
      '';
      hermes-agent-a2a-env.content =
        let
          topology = ai.a2aTopology config.networking.hostName;
        in
        ''
          A2A_PORT=9900
          A2A_AGENT_NAME=${config.networking.hostName}
          A2A_OWN_TOKEN=${config.sops.placeholder."${ai.mkA2aTokenSecretName config.networking.hostName}"}
          A2A_PEER_TOKENS=${ai.mkA2aPeerTokens config.sops.placeholder (ai.mkSelfExcludedPeers config.networking.hostName ai.peers)}
          A2A_TRUSTED_PEERS=${ai.mkA2aTrustedPeers topology.trusted}
        '';
    };
  };
}
