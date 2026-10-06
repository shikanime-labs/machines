{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  toDhall = generators.toDhall { };
  hermesLcmPlugin = import ../../../pkgs/hermes-plugin-lcm { inherit pkgs; };
  memoryWikiPlugin = import ../../../pkgs/hermes-plugin-memory-wiki { inherit pkgs; };
  ponytailPlugin = import ../../../pkgs/hermes-plugin-ponytail { inherit pkgs; };

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
    powershell-editor-services
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

  powershellEditorServices = pkgs.powershell-editor-services;
in
{
  imports = [
    ../../../modules/home/base.nix
    ../../../modules/home/cloud.nix
    ../../../modules/home/fontconfig.nix
    ../../../modules/home/ghostty.nix
    ../../../modules/home/helix.nix
    ../../../modules/home/starship.nix
    ../../../modules/home/vcs.nix
    ../../../modules/home/workstation.nix
    ../../../modules/home/zed-editor.nix
  ];

  home.sessionVariables.SSH_AUTH_SOCK = "${config.home.homeDirectory}/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock";

  identities = {
    enable = true;

    ghstack.enable = true;

    glab.enable = true;

    gouv = {
      enable = true;
      git.condition = "gitpath:${config.home.homeDirectory}/Source/Repos/github.com/cloud-pi-native";
      jj.extraConfig."--when".repositories = [
        "${config.home.homeDirectory}/Source/Repos/github.com/cloud-pi-native"
      ];
    };

    automata = {
      enable = true;
      git.condition = "gitpath:${config.home.homeDirectory}/Source/Repos/github.com/yorha-automata";
      jj.extraConfig."--when".repositories = [
        "${config.home.homeDirectory}/Source/Repos/github.com/yorha-automata"
      ];
    };

    shikanime.enable = true;
  };

  programs = {
    bash.enable = true;

    docker-cli = {
      contexts.rancher-desktop = {
        Endpoints = {
          docker = {
            Host = "unix://${config.home.homeDirectory}/.rd/docker.sock";
            SkipTLSVerify = false;
          };
        };
        Metadata.Description = "Rancher Desktop moby context";
      };
      settings = {
        credsStore = "osxkeychain";
        currentContext = "rancher-desktop";
      };
    };

    zsh.enable = true;

    hermes-agent.enable = true;
  };

  services.hermes-agent = {
    enable = true;

    extraPlugins = [
      hermesLcmPlugin
      memoryWikiPlugin
      ponytailPlugin
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
      "matrix"
    ];

    settings = {
      context.engine = "lcm";

      custom_providers = [
        {
          name = "shikanime-anthropic";
          base_url = "https://inference.i.shikanime.studio/anthropic";
          api_mode = "anthropic_messages";
          key_env = "SKS_API_KEY";
          session_affinity_header = "x-sks-session-id";
          model = "z-ai/glm-5.3";
          models = [
            "z-ai/glm-5.3"
            "z-ai/glm-5.3-flash"
            "qwen/qwen3.8-27b"
            "qwen/qwen3.8-flash"
          ];
        }
        {
          name = "shikanime-openai";
          base_url = "https://inference.i.shikanime.studio/v1";
          api_mode = "chat_completions";
          key_env = "SKS_API_KEY";
          session_affinity_header = "x-sks-session-id";
          model = "poolside/laguna-s-2.1:free";
          models = [
            "poolside/laguna-s-2.1:free"
            "qwen/qwen3.8-flash"
            "qwen/qwen3.8-27b"
          ];
        }
      ];

      fallback_providers = [
        {
          api_mode = "anthropic_messages";
          model = "qwen/qwen3.8-flash";
          provider = "custom:shikanime-anthropic";
        }
        {
          api_mode = "anthropic_messages";
          model = "deepseek/deepseek-v4.1";
          provider = "custom:shikanime-anthropic";
        }
      ];

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

      plugins = {
        enabled = [
          "disk-cleanup"
          "hermes-lcm"
          "memory-wiki"
          "ponytail"
          "security-guidance"
        ];
        entries = {
          hermes-lcm.allow_tool_override = true;
          ponytail.allow_tool_override = true;
        };
      };

      lsp.servers.powershell.command = [
        "${powershellEditorServices}/lib/powershell-editor-services"
      ];

      memory.provider = "honcho";

      sessions.auto_prune = true;

      platforms.a2a.enabled = true;

      a2a_agents.nishir = {
        capabilities = [
          "command"
          "workstation"
        ];
        url = "https://nishir.taila659a.ts.net:9900";
        auth = {
          type = "bearer";
          token = "\${env:A2A_OWN_TOKEN}";
        };
      };

      platform_toolsets.cli = [
        "hermes-cli"
        "a2a"
      ];

      moa = {
        default_preset = "default";
        presets = {
          broad = {
            reference_models = [
              {
                provider = "shikanime-openai";
                model = "deepseek/deepseek-v4-flash";
              }
              {
                provider = "shikanime-anthropic";
                model = "z-ai/glm-5.3";
              }
              {
                provider = "shikanime-openai";
                model = "openai/gpt-5.5";
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
                model = "deepseek/deepseek-v4-flash";
              }
              {
                provider = "shikanime-openai";
                model = "openai/gpt-5.5";
              }
            ];
            aggregator = {
              provider = "shikanime-openai";
              model = "openai/gpt-5.5";
            };
            enabled = true;
            fanout = "user_turn";
          };
        };
      };
    };
  };

  nix.extraOptions = "!include ${config.sops.templates.nix-user-config.path}";

  # A2A gateway — hub-only trust: the A2A platform served on 0.0.0.0:9900,
  # outbound peer nishir, own and peer tokens from the shared machine
  # secrets, nishir the only trusted peer.
  services.hermes-agent.gateway.enable = true;

  sops = {
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    defaultSopsFile = ../../../secrets/shikanime.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets.cachix-token = { };
    secrets.github-token = { };
    secrets."hermes-agent-a2a-token-telsha".sopsFile = ../../../secrets/machine.enc.yaml;
    secrets."hermes-agent-a2a-token-nishir".sopsFile = ../../../secrets/machine.enc.yaml;
    templates.cachix-config.content = toDhall {
      authToken = config.sops.placeholder.cachix-token;
      hostname = "https://cachix.org";
    };
    templates.nix-user-config.content = ''
      extra-access-tokens = github.com=${config.sops.placeholder.github-token}
    '';
    templates.hermes-a2a-env.content = ''
      A2A_PORT=9900
      A2A_AGENT_NAME=telsha
      A2A_PUBLIC_URL=https://telsha.taila659a.ts.net:9900
      A2A_HOST=0.0.0.0
      A2A_OWN_TOKEN=${config.sops.placeholder."hermes-agent-a2a-token-telsha"}
      A2A_PEER_TOKENS=nishir:${config.sops.placeholder."hermes-agent-a2a-token-nishir"}
      A2A_TRUSTED_PEERS=nishir
    '';
  };

  xdg.configFile."cachix/cachix.dhall".source =
    config.lib.file.mkOutOfStoreSymlink config.sops.templates.cachix-config.path;
}
