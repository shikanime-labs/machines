{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  mkSshHeadlessHost = user: {
    User = user;
    SetEnv.TERM = "xterm-256color";
  };

  mkSshWorkstationHost = user: {
    ForwardX11 = true;
    User = user;
    SetEnv.TERM = "xterm-256color";
  };

  hermesLcmPlugin = import ../../pkgs/hermes-plugin-lcm { inherit pkgs; };
  rtkRewritePlugin = import ../../pkgs/hermes-plugin-rtk-rewrite { inherit pkgs; };
  ponytailPlugin = import ../../pkgs/hermes-plugin-ponytail { inherit pkgs; };
in
{
  catppuccin = {
    enable = true;
    flavor = "latte";
  };

  home = {
    packages = with pkgs; [
      cachix
      devenv
      docker-credential-helpers
      pass
      qpdf
      rclone
      wget
      zip
    ];
    sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];
  };

  programs = {
    bat.enable = true;

    btop.enable = true;

    carapace.enable = true;

    command-not-found.enable = true;

    dircolors.enable = true;

    direnv = {
      enable = true;
      mise.enable = true;
      nix-direnv.enable = true;
      config.global.load_dotenv = true;
    };

    docker-cli.enable = true;

    gpg.enable = true;

    hermes-agent.enable = true;

    jujutsu.settings."merge-tools".mergiraf."merge-tool-edits-conflict-markers" = true;

    mergiraf = {
      enable = true;
      enableGitIntegration = true;
      enableJujutsuIntegration = true;
    };

    mise.enable = true;

    nushell = {
      enable = true;
      extraConfig = ''
        $env.config.show_banner = false

        source ${pkgs.nu_scripts}/share/nu_scripts/custom-completions/vscode/vscode-completions.nu
      '';
    };

    pay-respects.enable = true;

    ripgrep.enable = true;

    ssh = {
      enable = true;
      settings = {
        "ashira.taila659a.ts.net" = mkSshHeadlessHost "nishir";
        "catbox.taila659a.ts.net" = mkSshHeadlessHost "shika";
        "fushi.taila659a.ts.net" = mkSshHeadlessHost "nishir";
        "kushira.taila659a.ts.net" = mkSshHeadlessHost "nishir";
        "manash.taila659a.ts.net" = mkSshHeadlessHost "nishir";
        "minish.taila659a.ts.net" = mkSshHeadlessHost "nishir";
        "nalsha.taila659a.ts.net" = mkSshHeadlessHost "nishir";
        "nemishi.taila659a.ts.net" = mkSshHeadlessHost "nishir";
        "nixtar.taila659a.ts.net" = mkSshWorkstationHost "shika";
        "sashina.taila659a.ts.net" = mkSshHeadlessHost "nishir";
        "thinkcentre-m710t.tailfb4bb2.ts.net" = mkSshWorkstationHost "william-phetsinorath";
      };
    };

    zoxide.enable = true;
  };

  # Hermes Agent — declarative config ported from modules/nixos/profiles/ai.nix,
  # minus the fleet/gateway/automation surface (matrix, a2a, bot_peers,
  # platforms, platform_toolsets, honcho memory, sops environmentFiles).
  # backend.mode defaults to "none" and gateway.enable defaults to false, so
  # enabling the service writes config.yaml without launching any daemon.
  services.hermes-agent = {
    enable = true;

    extraPlugins = [
      hermesLcmPlugin
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
    ];

    settings = {
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
          model = "z-ai/glm-5.3";
          provider = "custom:shikanime-anthropic";
        }
        {
          api_mode = "anthropic_messages";
          model = "deepseek/deepseek-v4-flash";
          provider = "custom:shikanime-anthropic";
        }
      ];

      model = {
        default = "qwen/qwen3.8-27b";
        provider = "custom:shikanime-anthropic";
        base_url = "https://inference.i.shikanime.studio/anthropic";
      };

      display = {
        busy_input_mode = "steer";
        interface = "tui";
        streaming = true;
      };

      plugins = {
        enabled = [
          "disk-cleanup"
          "hermes-lcm"
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

      sessions.auto_prune = true;
    };
  };

  xdg.enable = true;
}
