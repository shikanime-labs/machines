{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    environmentFiles = [
      config.sops.templates.hermes-agent-env.path
      config.sops.templates.hermes-agent-matrix-env.path
    ];
    extraPackages = with pkgs; [
      curl
      corepack
      gh
      git
      honcho
      nodejs
      yarn
    ];
    settings = {
      custom_providers = [
        {
          name = "aperture";
          base_url = "https://ai.taila659a.ts.net/v1";
        }
      ];
      documents."honcho.json" = builtins.toJSON {
        baseUrl = "https://honcho.taila659a.ts.net";
        hosts.hermes = {
          peerName = config.networking.hostName;
          aiPeer = "telsha";
          workspace = "hermes";
          observationMode = "directional";
          writeFrequency = "async";
          recallMode = "hybrid";
          dialecticCadence = 3;
          sessionStrategy = "per-session";
          enabled = true;
          saveMessages = true;
          dialecticReasoningLevel = "low";
          pinPeerName = false;
        };
      };
      fallback_providers = [
        {
          api_mode = "chat_completions";
          model = "labs-leanstral-2603";
          provider = "custom:aperture";
        }
        {
          api_mode = "chat_completions";
          model = "stepfun/step-3.7-flash:free";
          provider = "custom:aperture";
        }
      ];
      matrix = {
        allowed_rooms = [ "!QUaAaCBlSIBcYyOyLb:matrix.taila659a.ts.net" ];
        allowed_users = [
          "@admin:matrix.taila659a.ts.net"
          "@shikanime:matrix.taila659a.ts.net"
        ];
        session_scope = "room";
      };
      memory.provider = "honcho";
      model = {
        default = "openrouter/free";
        provider = "custom:aperture";
      };
      mcp_servers.aperture = {
        url = "http://ai.taila659a.ts.net/v1/mcp";
        enabled = true;
      };
    };
    extraDependencyGroups = [
      "honcho"
      "matrix"
    ];
  };

  sops = {
    secrets = {
      hermes-agent-api-server-key = {
        group = "hermes";
        owner = "hermes";
        restartUnits = [ "hermes-agent.service" ];
      };
      hermes-agent-matrix-access-token = {
        group = "hermes";
        owner = "hermes";
        restartUnits = [ "hermes-agent.service" ];
      };
      hermes-agent-matrix-recovery-key = {
        group = "hermes";
        owner = "hermes";
        restartUnits = [ "hermes-agent.service" ];
        mode = "0600";
      };
    };
    templates = {
      hermes-agent-env = {
        content = ''
          API_SERVER_ENABLED=true
          API_SERVER_KEY=${config.sops.placeholder.hermes-agent-api-server-key}
        '';
      };
      hermes-agent-matrix-env = {
        content = ''
          MATRIX_HOMESERVER=https://matrix.taila659a.ts.net/
          MATRIX_ACCESS_TOKEN=${config.sops.placeholder.hermes-agent-matrix-access-token}
          MATRIX_E2EE_MODE=required
          MATRIX_HOME_ROOM=!QUaAaCBlSIBcYyOyLb:matrix.taila659a.ts.net
          MATRIX_RECOVERY_KEY_FILE=${config.sops.secrets.hermes-agent-matrix-recovery-key.path}
        '';
        restartUnits = [ "hermes-agent.service" ];
      };
    };
  };
}
