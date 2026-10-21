{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  ai = import ../lib/ai.nix { inherit lib; };

  hostName = osConfig.networking.hostName;
  topology = ai.a2aTopology hostName;

  hermesHonchoPlugin =
    config.services.hermes-agent.package.python.pkgs.callPackage ../../pkgs/hermes-plugin-honcho
      { };
  hermesLcmPlugin = pkgs.callPackage ../../pkgs/hermes-plugin-lcm { };
  honchoAi = config.services.hermes-agent.package.python.pkgs.callPackage ../../pkgs/honcho-ai { };
  memoryWikiPlugin = pkgs.callPackage ../../pkgs/hermes-plugin-memory-wiki { };
  ponytailPlugin = pkgs.callPackage ../../pkgs/hermes-plugin-ponytail { };
in
{
  home.stateVersion = "26.05";

  programs.git = {
    enable = true;
    extraConfig.commit.gpgsign = false;
    userEmail = "243783539+yorha-operator@users.noreply.github.com";
    userName = "YoRHa Operator";
  };

  programs.hermes-agent = {
    enable = true;
    package = config.services.hermes-agent.package;
  };

  services.hermes-agent = {
    enable = true;
    workingDirectory = "/var/lib/hermes";
    gateway.enable = true;

    environment.XDG_DATA_DIRS = "/etc/profiles/per-user/hermes/share";

    environmentFiles = [
      osConfig.sops.templates.hermes-agent-env.path
      osConfig.sops.templates.hermes-agent-matrix-env.path
      osConfig.sops.templates.hermes-agent-a2a-env.path
      osConfig.sops.templates.hermes-agent-peer-keys-env.path
      osConfig.sops.templates.hermes-agent-providers-env.path
    ];
    extraPackages = with pkgs; [
      agent-browser
      curl
      ffmpeg
      gh
      git
      kubectl
      nodejs
      yarn
      tigervnc
      xfce.xfwm4
      xfce.xfce4-panel
      xfce.xfdesktop
      xfce.xfce4-settings
      xfce.xfce4-terminal
      dbus
      setxkbmap
      xauth
      xdpyinfo
      xprop
      xset
      xsetroot
      gnome-themes-extra
      papirus-icon-theme
      dejavu_fonts.minimal
    ];
    extraPlugins = [
      hermesLcmPlugin
      memoryWikiPlugin
      ponytailPlugin
    ];
    extraPythonPackages = [
      honchoAi
      hermesHonchoPlugin
    ];
    hermesHomeFiles."honcho.json" = builtins.toJSON {
      baseUrl = "https://honcho.i.shikanime.studio";
      hosts.hermes = {
        peerName = hostName;
        aiPeer = "hermes";
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
    settings = {
      bot_desktop.auto_start = true;
      context.engine = "lcm";
      dashboard.oauth.self_hosted = {
        client_id = "hermes-agent";
        issuer = "https://accounts.i.shikanime.studio";
        scopes = "openid profile email offline_access";
      };
      providers = {
        shikanime-anthropic = {
          api = "https://inference.i.shikanime.studio/anthropic";
          transport = "anthropic_messages";
          key_env = "SKS_API_KEY";
          session_affinity_header = "x-sks-session-id";
          default_model = "qwen/qwen3.8-flash";
          models = [
            "z-ai/glm-5.3-flash"
            "z-ai/glm-5.3"
            "qwen/qwen3.8-flash"
          ];
        };
        shikanime-openai = {
          api = "https://inference.i.shikanime.studio/v1";
          transport = "chat_completions";
          key_env = "SKS_API_KEY";
          session_affinity_header = "x-sks-session-id";
          default_model = "qwen/qwen3.8-flash";
          models = [ "qwen/qwen3.8-flash" ];
        };
      };
      fallback_providers = [
        {
          api_mode = "anthropic_messages";
          model = "qwen/qwen3.8-flash";
          provider = "custom:shikanime-anthropic";
        }
        {
          api_mode = "anthropic_messages";
          model = "deepseek/deepseek-flash-latest";
          provider = "custom:shikanime-anthropic";
        }
      ];
      matrix = {
        allowed_rooms = [ "#automata:matrix.taila659a.ts.net" ];
        allowed_users = [
          "@admin:matrix.taila659a.ts.net"
          "@shikanime:matrix.taila659a.ts.net"
        ];
      };
      memory.provider = "honcho";
      sessions.auto_prune = true;
      model = {
        default = "qwen/qwen3.8-flash";
        provider = "custom:shikanime-anthropic";
        base_url = "https://inference.i.shikanime.studio/anthropic";
      };
      display = {
        bell_on_complete = true;
        bell_on_prompt = true;
        busy_input_mode = "steer";
        interface = "tui";
        show_cost = true;
        show_reasoning = true;
        streaming = true;
      };
      platforms.a2a.enabled = true;
      a2a_agents = ai.mkA2aAgents topology.targets;
      bot_peers = ai.mkBotPeers (
        ai.mkSelfExcludedPeers {
          inherit hostName;
          inherit (ai) peers;
        }
      );
      platform_toolsets = {
        cli = [
          "hermes-cli"
          "a2a"
        ];
        matrix = [
          "hermes-matrix"
          "a2a"
        ];
        api_server = [
          "hermes-api-server"
          "a2a"
        ];
      };
      plugins.enabled = [
        "disk-cleanup"
        "hermes-lcm"
        "honcho"
        "memory-wiki"
        "platforms/a2a-platform"
        "ponytail"
        "platforms/matrix"
        "security-guidance"
      ];
      moa = {
        default_preset = "default";
        presets = {
          broad = {
            reference_models = [
              {
                provider = "shikanime-openai";
                model = "deepseek/deepseek-flash-latest";
              }
              {
                provider = "shikanime-anthropic";
                model = "z-ai/glm-5.3";
              }
              {
                provider = "shikanime-openai";
                model = "openai/gpt-6-luna";
              }
              {
                provider = "shikanime-openai";
                model = "openai/gpt-5.5-mini";
              }
            ];
            aggregator = {
              provider = "shikanime-anthropic";
              model = "z-ai/glm-5.3-flash";
            };
            enabled = true;
          };
          default = {
            reference_models = [
              {
                provider = "shikanime-anthropic";
                model = "z-ai/glm-5.3";
              }
              {
                provider = "shikanime-openai";
                model = "deepseek/deepseek-flash-latest";
              }
              {
                provider = "shikanime-openai";
                model = "openai/gpt-6-luna";
              }
            ];
            aggregator = {
              provider = "shikanime-openai";
              model = "openai/gpt-6-luna";
            };
            enabled = true;
            fanout = "user_turn";
          };
        };
      };
      stt.local.model = "medium";
      tts.provider = "piper";
    };
    extraDependencyGroups = [
      "anthropic"
      "computer-use"
      "matrix"
      "messaging"
      "piper"
      "voice"
    ];
    backend = {
      mode = "dashboard";
      sessionTokenFile = osConfig.sops.secrets.hermes-agent-desktop-token.path;
    };
  };
}
