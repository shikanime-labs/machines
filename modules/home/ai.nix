{ pkgs, ... }:

let
  hermesLcmPlugin = import ../../pkgs/hermes-plugin-lcm { inherit pkgs; };
  memoryWikiPlugin = import ../../pkgs/hermes-plugin-memory-wiki { inherit pkgs; };
  rtkRewritePlugin = import ../../pkgs/hermes-plugin-rtk-rewrite { inherit pkgs; };
  ponytailPlugin = import ../../pkgs/hermes-plugin-ponytail { inherit pkgs; };
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
      rtkRewritePlugin
      ponytailPlugin
    ];

    extraPackages = with pkgs; [
      agent-browser
      curl
      gh
      git
      nodejs
      rtk
      yarn
    ];

    extraDependencyGroups = [
      "anthropic"
      "computer-use"
      "honcho"
    ];

    settings = {
      agent.verify_on_stop = "auto";

      context.engine = "lcm";

      custom_providers = [
        {
          name = "shikanime-anthropic";
          base_url = "https://inference.i.shikanime.studio/anthropic";
          api_mode = "anthropic_messages";
          key_env = "SKS_API_KEY";
          model = "z-ai/glm-5.3-flash";
          models = [
            "z-ai/glm-5.3-flash"
            "z-ai/glm-5.3"
            "qwen/qwen3.8-27b"
            "qwen/qwen3.8-flash"
            "deepseek/deepseek-v4-flash"
          ];
        }
        {
          name = "shikanime-openai";
          base_url = "https://inference.i.shikanime.studio/v1";
          api_mode = "chat_completions";
          key_env = "SKS_API_KEY";
          model = "poolside/laguna-s-2.1:free";
          models = [
            "poolside/laguna-s-2.1:free"
            "qwen/qwen3.8-flash"
            "qwen/qwen3.8-27b"
            "deepseek/deepseek-v4-flash"
          ];
        }
      ];

      fallback_providers = [
        {
          api_mode = "anthropic_messages";
          model = "qwen/qwen3.8-flash";
          provider = "custom:shikanime-anthropic";
        }
      ];

      model = {
        default = "z-ai/glm-5.3-flash";
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
          "rtk-rewrite"
          "security-guidance"
        ];
        entries = {
          hermes-lcm.allow_tool_override = true;
          ponytail.allow_tool_override = true;
          rtk-rewrite.allow_tool_override = true;
        };
      };

      memory.provider = "honcho";

      sessions.auto_prune = true;
    };
  };
}
