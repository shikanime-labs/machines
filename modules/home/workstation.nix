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
        "manash.taila659a.ts.net" = mkSshHeadlessHost "nishir";
        "minish.taila659a.ts.net" = mkSshHeadlessHost "nishir";
        "nalsha.taila659a.ts.net" = mkSshHeadlessHost "nishir";
        "nemishi.taila659a.ts.net" = mkSshHeadlessHost "nishir";
        "nixtar.taila659a.ts.net" = mkSshWorkstationHost "shika";
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
          model = "tencent/hy3:free";
          models = [
            "deepseek/deepseek-v4-flash"
            "gemini-2.5-flash"
            "gemini-2.5-flash-lite"
            "gemini-2.5-pro"
            "gemini-3-flash-preview"
            "google/gemma-4-e2b"
            "inclusionai/ling-3.0-flash:free"
            "labs-leanstral-1-5"
            "nvidia/nemotron-3-ultra-550b-a55b:free"
            "openrouter/openrouter/free"
            "poolside/laguna-xs-2.1:free"
            "qwen/qwen3-8b"
            "stepfun/step-3.7-flash:free"
            "tencent/hy3:free"
          ];
        }
      ];

      fallback_providers = [
        {
          api_mode = "chat_completions";
          model = "inclusionai/ling-3.0-flash:free";
          provider = "custom:aperture-openai";
        }
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
          model = "tencent/hy3:free";
          provider = "custom:aperture-openai";
        }
      ];

      model = {
        default = "tencent/hy3:free";
        provider = "custom:aperture-openai";
        base_url = "https://ai.taila659a.ts.net/v1";
      };

      auxiliary = {
        vision = {
          provider = "custom:aperture-openai";
          model = "tencent/hy3:free";
          base_url = "https://ai.taila659a.ts.net/v1";
        };
        web_extract = {
          provider = "custom:aperture-openai";
          model = "tencent/hy3:free";
          base_url = "https://ai.taila659a.ts.net/v1";
        };
        compression = {
          provider = "custom:aperture-openai";
          model = "tencent/hy3:free";
          base_url = "https://ai.taila659a.ts.net/v1";
        };
        skills_hub = {
          provider = "custom:aperture-openai";
          model = "tencent/hy3:free";
          base_url = "https://ai.taila659a.ts.net/v1";
        };
        approval = {
          provider = "custom:aperture-openai";
          model = "tencent/hy3:free";
          base_url = "https://ai.taila659a.ts.net/v1";
        };
        mcp = {
          provider = "custom:aperture-openai";
          model = "tencent/hy3:free";
          base_url = "https://ai.taila659a.ts.net/v1";
        };
        title_generation = {
          provider = "custom:aperture-openai";
          model = "tencent/hy3:free";
          base_url = "https://ai.taila659a.ts.net/v1";
        };
        memory_query_rewrite = {
          provider = "custom:aperture-anthropic:openai";
          model = "tencent/hy3:free";
          base_url = "https://ai.taila659a.ts.net/v1";
        };
        tts_audio_tags = {
          provider = "custom:aperture-openai";
          model = "tencent/hy3:free";
          base_url = "https://ai.taila659a.ts.net/v1";
        };
        triage_specifier = {
          provider = "custom:aperture-openai";
          model = "tencent/hy3:free";
          base_url = "https://ai.taila659a.ts.net/v1";
        };
        kanban_decomposer = {
          provider = "custom:aperture-openai";
          model = "tencent/hy3:free";
          base_url = "https://ai.taila659a.ts.net/v1";
        };
        profile_describer = {
          provider = "custom:aperture-openai";
          model = "tencent/hy3:free";
          base_url = "https://ai.taila659a.ts.net/v1";
        };
        curator = {
          provider = "custom:aperture-openai";
          model = "tencent/hy3:free";
          base_url = "https://ai.taila659a.ts.net/v1";
        };
      };

      mcp_servers.aperture = {
        url = "https://ai.taila659a.ts.net/v1/mcp";
        enabled = true;
      };

      display = {
        interface = "tui";
        streaming = true;
      };

      plugins.enabled = [
        "disk-cleanup"
        "hermes-lcm"
        "rtk-rewrite"
        "security-guidance"
      ];
    };
  };

  xdg.enable = true;
}
