{ pkgs, ... }:

let
  hermesLcmPlugin = import ../../pkgs/hermes-plugin-lcm { inherit pkgs; };
  memoryWikiPlugin = import ../../pkgs/hermes-plugin-memory-wiki { inherit pkgs; };
  ponytailPlugin = import ../../pkgs/hermes-plugin-ponytail { inherit pkgs; };

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
    julia
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
in
{
  home.packages = with pkgs; [
    qwen-code
  ];

  programs = {
    antigravity-cli.enable = true;

    codex.enable = true;

    claude-code.enable = true;

    hermes-agent.enable = true;
  };

  # Hermes Agent — declarative config ported from modules/nixos/profiles/ai.nix,
  # minus the fleet/gateway/automation surface (matrix, a2a, bot_peers,
  # platforms, platform_toolsets, sops environmentFiles).
  # backend.mode defaults to "none" and gateway.enable defaults to false, so
  # enabling the service writes config.yaml without launching any daemon.
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
      "honcho"
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
        "${pkgs.powershell-editor-services}/lib/powershell-editor-services"
      ];

      memory.provider = "honcho";

      sessions.auto_prune = true;
    };
  };
}
