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

  hubPeers = [
    {
      name = "automata";
      capabilities = [
        "command"
        "workstation"
      ];
      url = "https://a2a.automata.i.shikanime.studio";
    }
  ];

  fleetPeers = ai.mkSelfExcludedPeers {
    inherit hostName;
    peers = hubPeers;
  };

  hermesHonchoPlugin =
    config.services.hermes-agent.package.python.pkgs.callPackage ../../pkgs/hermes-plugin-honcho
      { };
  hermesLcmPlugin = pkgs.callPackage ../../pkgs/hermes-plugin-lcm { };
  honchoAi = config.services.hermes-agent.package.python.pkgs.callPackage ../../pkgs/honcho-ai { };
  lspBackends = with pkgs; [
    astro-language-server
    bash-language-server
    beamPackages.elixir-ls
    clang-tools
    clojure-lsp
    dart
    dockerfile-language-server
    gleam
    gopls
    haskell-language-server
    intelephense
    jdt-language-server
    kotlin-language-server
    lua-language-server
    nixd
    ocamlPackages.ocaml-lsp
    powershell
    prisma_7
    pyright
    shellcheck
    svelte-language-server
    terraform-ls
    typescript-language-server
    vue-language-server
    yaml-language-server
    zls
  ];
  memoryWikiPlugin = pkgs.callPackage ../../pkgs/hermes-plugin-memory-wiki { };
  ponytailPlugin = pkgs.callPackage ../../pkgs/hermes-plugin-ponytail { };
  powershellEditorServices = pkgs.powershell-editor-services;
in
{
  services.hermes-agent = {
    enable = true;

    environmentFiles = [
      config.sops.templates.hermes-agent-env.path
      config.sops.templates.hermes-agent-a2a-env.path
      config.sops.templates.hermes-agent-peer-keys-env.path
      config.sops.templates.hermes-agent-providers-env.path
    ];

    gateway.enable = true;

    extraPlugins = [
      hermesLcmPlugin
      memoryWikiPlugin
      ponytailPlugin
    ];
    extraPythonPackages = [
      honchoAi
      hermesHonchoPlugin
    ];
    extraPackages =
      with pkgs;
      [
        agent-browser
        curl
        gh
        git
        nodejs
        yarn
      ]
      ++ lspBackends;

    extraDependencyGroups = [
      "anthropic"
      "computer-use"
      "messaging"
    ];

    backend = {
      mode = "dashboard";
      sessionTokenFile = config.sops.secrets.hermes-agent-desktop-token.path;
    };

    settings = {
      context.engine = "lcm";

      dashboard.oauth.self_hosted = {
        client_id = "hermes-agent";
        issuer = "https://accounts.i.shikanime.studio";
      };

      providers = {
        shikanime-anthropic = {
          api = "https://inference.i.shikanime.studio/anthropic";
          transport = "anthropic_messages";
          key_env = "SKS_API_KEY";
          session_affinity_header = "x-sks-session-id";
          default_model = "z-ai/glm-5.3";
          models = [
            "z-ai/glm-5.3"
            "z-ai/glm-5.3-flash"
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

      memory.provider = "honcho";

      sessions.auto_prune = true;

      model = {
        default = "z-ai/glm-5.3";
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

      a2a_agents = ai.mkA2aAgents fleetPeers;

      bot_peers = ai.mkBotPeers fleetPeers;

      platform_toolsets = {
        cli = [
          "hermes-cli"
          "a2a"
        ];
        api_server = [
          "hermes-api-server"
          "a2a"
        ];
      };

      plugins = {
        enabled = [
          "disk-cleanup"
          "hermes-lcm"
          "honcho"
          "memory-wiki"
          "platforms/a2a-platform"
          "ponytail"
          "security-guidance"
        ];
        entries = {
          hermes-lcm.allow_tool_override = true;
          ponytail.allow_tool_override = true;
        };
      };

      lsp.servers.powershell.command = [ "${powershellEditorServices}/lib/powershell-editor-services" ];

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
    };
  };

  sops = {
    secrets = {
      hermes-agent-desktop-token.sopsFile = ../../secrets/machine.enc.yaml;
      hermes-agent-sks-api-key.sopsFile = ../../secrets/machine.enc.yaml;
      hermes-agent-github-token.sopsFile = ../../secrets/machine.enc.yaml;
    }
    // (ai.mkA2aTokenSecrets {
      sopsFile = ../../secrets/machine.enc.yaml;
      inherit (ai) peers;
    })
    // (ai.mkPeerApiServerKeySecrets {
      sopsFile = ../../secrets/machine.enc.yaml;
      inherit (ai) peers;
    });

    templates = {
      hermes-agent-env.content = ''
        API_SERVER_ENABLED=true
        API_SERVER_KEY=${config.sops.placeholder."${ai.mkPeerApiServerKeyName hostName}"}
      '';
      hermes-agent-providers-env.content = ''
        SKS_API_KEY=${config.sops.placeholder.hermes-agent-sks-api-key}
        GITHUB_TOKEN=${config.sops.placeholder.hermes-agent-github-token}
      '';
      hermes-agent-a2a-env.content = ''
        A2A_PORT=9900
        A2A_AGENT_NAME=${hostName}
        A2A_OWN_TOKEN=${config.sops.placeholder."${ai.mkA2aTokenSecretName hostName}"}
        A2A_PEER_TOKENS=${
          ai.mkA2aPeerTokens {
            placeholder = config.sops.placeholder;
            peers = fleetPeers;
          }
        }
        A2A_TRUSTED_PEERS=${ai.mkA2aTrustedPeers fleetPeers}
      '';
      hermes-agent-peer-keys-env.content = toString (
        ai.mkPeerKeyEnvs {
          placeholder = config.sops.placeholder;
          peers = fleetPeers;
        }
      );
    };
  };
}
