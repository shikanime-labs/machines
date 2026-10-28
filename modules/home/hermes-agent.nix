# The fleet hermes-agent service, evaluated in the operator user's
# home-manager scope. Imported by modules/nixos/users/operator-*.nix under
# home-manager.users.<operator>. Sops decrypts in this HM scope with the
# node age key; the system layer keeps no hermes secrets.
{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  topology = import ./hermes-topology.nix { inherit lib; };
  libH = import ../lib/hermes.nix { inherit lib; };
  t = topology.targets osConfig.networking.hostName;

  hermesHonchoPlugin =
    osConfig.services.hermes-agent.package.python.pkgs.callPackage ../../pkgs/hermes-plugin-honcho
      { };

  hermesLcmPlugin = pkgs.callPackage ../../pkgs/hermes-plugin-lcm { };
  honchoAi = osConfig.services.hermes-agent.package.python.pkgs.callPackage ../../pkgs/honcho-ai { };
  memoryWikiPlugin = pkgs.callPackage ../../pkgs/hermes-plugin-memory-wiki { };
  ponytailPlugin = pkgs.callPackage ../../pkgs/hermes-plugin-ponytail { };


in
{
  home.stateVersion = "26.05";

  # The identities module renders git config from sops templates; the
  # home-manager sops instance decrypts with the node's age key.
  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";

    # The secrets below rely on this default file; machine.enc.yaml carries
    # every fleet-shared token.
    defaultSopsFile = lib.mkDefault ../../secrets/machine.enc.yaml;
    defaultSopsFormat = "yaml";
  };

  # Hermes-agent secrets decrypt in the operator's HM scope; the node age
  # key above is the only credential source this needs.
  sops.secrets = {
    hermes-agent-matrix-access-token = { };
    hermes-agent-matrix-recovery-key.mode = "0600";
    hermes-agent-sks-api-key = { };
    hermes-agent-github-token = { };
  };

  sops.templates = {
    hermes-agent-env.content = ''
      API_SERVER_ENABLED=true
      API_SERVER_KEY=${
        osConfig.sops.placeholder."hermes-agent-api-server-key-${osConfig.networking.hostName}"
      }
    '';
    hermes-agent-peer-keys-env.content = toString (libH.mkPeerKeyEnvs osConfig.sops.placeholder t.otherPeers);
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
    hermes-agent-a2a-env.content = ''
      A2A_PORT=9900
      A2A_AGENT_NAME=${osConfig.networking.hostName}
      A2A_OWN_TOKEN=${osConfig.sops.placeholder."hermes-agent-a2a-token-${osConfig.networking.hostName}"}
      A2A_PEER_TOKENS=${libH.mkA2aPeerTokens osConfig.sops.placeholder t.otherPeers}
      A2A_TRUSTED_PEERS=${libH.mkA2aTrustedPeers (t.a2aTargets ++ t.hubTrust)}
    '';
  };

  identities = {
    enable = true;
    automata = {
      enable = true;
      git.enable = true;
    };
  };

  programs.hermes-agent.enable = true;

  services.hermes-agent = {
    enable = true;
    # Required at home-manager level: without it only the backend user unit
    # starts and the messaging gateway silently vanishes.
    gateway.enable = true;
    # The opus patch lands via overrideAttrs on the system-level package
    # option; carry that derivation so the user units run the patched one.
    package = osConfig.services.hermes-agent.package;
    workingDirectory = "/var/lib/hermes";
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
        peerName = osConfig.networking.hostName;
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
      platforms.a2a.enabled = true;
      a2a_agents = libH.mkA2aAgents t.a2aTargets;
      bot_peers = libH.mkBotPeers t.otherPeers;
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
