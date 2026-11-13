{ config, pkgs, ... }:

# Fleet-wide hermes-agent configuration. Everything the hosts share lives next
# to the package that builds it; ai.nix keeps only what is derived per host
# (a2a peers, bot peers) and the sops wiring it owns.
{
  services.hermes-agent = {
    enable = true;
    workingDirectory = "/var/lib/hermes";
    addToSystemPackages = true;
    environment.XDG_DATA_DIRS = "/etc/profiles/per-user/hermes/share";
    environmentFiles = [
      config.sops.templates.hermes-agent-env.path
      config.sops.templates.hermes-agent-matrix-env.path
      config.sops.templates.hermes-agent-a2a-env.path
      config.sops.templates.hermes-agent-peer-keys-env.path
      config.sops.templates.hermes-agent-providers-env.path
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
      xfwm4
      xfce4-panel
      xfdesktop
      xfce4-settings
      xfce4-terminal
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
    extraPlugins = builtins.attrValues (import ./plugins.nix { inherit pkgs; });
    hermesHomeFiles."honcho.json" = builtins.toJSON {
      baseUrl = "https://honcho.i.shikanime.studio";
      hosts.hermes = {
        peerName = config.networking.hostName;
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
    backend = {
      mode = "dashboard";
      sessionTokenFile = config.sops.secrets.hermes-agent-desktop-token.path;
    };
  };
}
