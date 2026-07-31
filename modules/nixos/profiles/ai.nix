{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  services = {
    cua-driver.enable = true;

    hermes-agent = {
      enable = true;
      addToSystemPackages = true;
      environmentFiles = [
        config.sops.templates.hermes-agent-env.path
        config.sops.templates.hermes-agent-matrix-env.path
      ];
      extraPackages = with pkgs; [
        agent-browser
        curl
        corepack
        gh
        git
        graphify
        honcho
        nodejs
        rtk
        yarn
      ];
      settings = {
        context.engine = "lcm";
        custom_providers = [
          {
            name = "aperture-anthropic";
            base_url = "https://ai.taila659a.ts.net/v1";
            api_mode = "anthropic_messages";
            model = "glm-4.7";
            models = [
              "glm-4.7"
              "glm-5.2"
            ];
          }
          {
            name = "aperture-openai";
            base_url = "https://ai.taila659a.ts.net/v1";
            api_mode = "chat_completions";
            model = "openrouter/openrouter/free";
            models = [
              "inclusionai/ling-3.0-flash:free"
              "auxiliary"
              "coder"
              "dreamer"
              "operator"
              "gemini-2.5-flash"
              "gemini-2.5-flash-lite"
              "gemini-2.5-pro"
              "gemini-3-flash-preview"
              "google/gemma-4-e2b"
              "mistralai/ministral-3-3b"
              "nvidia/nemotron-3-nano-4b"
              "qwen/qwen3-8b"
              "labs-leanstral-1-5"
              "deepseek/deepseek-v4-flash"
              "stepfun/step-3.7-flash:free"
              "gpt-5"
              "gpt-5-chat-latest"
              "gpt-5-codex"
              "gpt-5-mini"
              "gpt-5-nano"
              "gpt-5.1"
              "gpt-5.1-chat-latest"
              "gpt-5.1-codex"
              "gpt-5.1-codex-max"
              "gpt-5.2"
              "gpt-5.2-chat-latest"
              "gpt-5.2-codex"
              "nvidia/nemotron-3-ultra-550b-a55b:free"
              "openrouter/openrouter/free"
              "poolside/laguna-xs-2.1:free"
              "google/gemma-4-e2b"
              "inclusionai/ling-3.0-flash:free"
            ];
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
            model = "poolside/laguna-s-2.1:free";
            provider = "custom:aperture-openai";
          }
          {
            api_mode = "chat_completions";
            model = "labs-leanstral-1-5";
            provider = "custom:aperture-openai";
          }
          {
            api_mode = "chat_completions";
            model = "stepfun/step-3.7-flash:free";
            provider = "custom:aperture-openai";
          }
          {
            api_mode = "chat_completions";
            model = "openrouter/openrouter/free";
            provider = "custom:aperture-openai";
          }
        ];
        matrix = {
          allowed_rooms = [ "!QUaAaCBlSIBcYyOyLb:matrix.taila659a.ts.net" ];
          allowed_users = [
            "@admin:matrix.taila659a.ts.net"
            "@shikanime:matrix.taila659a.ts.net"
          ];
        };
        memory.provider = "honcho";
        model = {
          default = "inclusionai/ling-3.0-flash:free";
          provider = "custom:aperture-openai";
          base_url = "https://ai.taila659a.ts.net/v1";
        };
        auxiliary = {
          vision = {
            provider = "custom:aperture-openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
          web_extract = {
            provider = "custom:aperture-openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
          compression = {
            provider = "custom:aperture-openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
          skills_hub = {
            provider = "custom:aperture-openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
          approval = {
            provider = "custom:aperture-openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
          mcp = {
            provider = "custom:aperture-openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
          title_generation = {
            provider = "custom:aperture-openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
          memory_query_rewrite = {
            provider = "custom:aperture-anthropic:openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
          tts_audio_tags = {
            provider = "custom:aperture-openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
          triage_specifier = {
            provider = "custom:aperture-openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
          kanban_decomposer = {
            provider = "custom:aperture-openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
          profile_describer = {
            provider = "custom:aperture-openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
          curator = {
            provider = "custom:aperture-openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
        };
        mcp_servers.aperture = {
          url = "https://ai.taila659a.ts.net/v1/mcp";
          enabled = true;
        };
        # Bare `hermes`/`hermes chat` launches the Ink TUI by default; token
        # streaming on for live agent output. Explicit --cli/--tui still wins.
        display = {
          interface = "tui";
          streaming = true;
        };
      };
      extraDependencyGroups = [
        "computer-use"
        "honcho"
        "matrix"
      ];
    };
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
