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

  # A2A peer mesh (darwin-only, telsha). Mirrors modules/nixos/profiles/ai.nix
  # `peers`; the Home Manager config has no networking.hostName, so the host
  # name is fixed here. Shared symmetric tokens live in secrets/shikanime.enc.yaml
  # (copied from secrets/machine.enc.yaml), so values must match the fleet.
  a2aHostName = "telsha";
  a2aPeers = [
    {
      name = "ashira";
      capabilities = [
        "build"
        "build-x86"
        "k8s-follower"
      ];
    }
    {
      name = "fushi";
      capabilities = [
        "build"
        "build-arm"
        "k8s-node"
      ];
    }
    {
      name = "manash";
      capabilities = [
        "build"
        "build-x86"
        "k8s-leader"
      ];
    }
    {
      name = "minish";
      capabilities = [
        "build"
        "build-arm"
        "k8s-node"
      ];
    }
    {
      name = "nalsha";
      capabilities = [
        "build"
        "build-x86"
        "k8s-follower"
      ];
    }
    {
      name = "nemishi";
      capabilities = [
        "build"
        "build-arm"
        "k8s-node"
      ];
    }
    {
      name = "nixtar";
      capabilities = [
        "graphical"
        "media"
        "nvidia"
        "k8s-leader"
      ];
    }
    {
      name = "sashina";
      capabilities = [
        "build-x86"
        "k8s-node"
      ];
    }
    {
      name = "kushira";
      capabilities = [
        "build-x86"
        "k8s-node"
      ];
    }
    {
      name = "nishir";
      capabilities = [
        "build-x86"
        "k8s-leader"
      ];
    }
    {
      name = "telsha";
      capabilities = [
        "command"
        "workstation"
        "darwin"
      ];
    }
  ];

  a2aOtherPeers = builtins.filter (p: p.name != a2aHostName) a2aPeers;

  mkA2aTrustedPeers = peers': lib.concatStringsSep "," (map (p: p.name) peers');

  mkA2aAgent =
    { name, capabilities }:
    {
      inherit capabilities;
      url = "https://${name}.taila659a.ts.net:9900";
      auth = {
        type = "bearer";
        token = "\\${"env:A2A_OWN_TOKEN"}";
      };
    };

  mkA2aAgents =
    peers': builtins.listToAttrs (map (peer: lib.nameValuePair peer.name (mkA2aAgent peer)) peers');

  mkA2aPeerToken =
    peer: "${peer.name}:${config.sops.placeholder."hermes-agent-a2a-token-${peer.name}"}";

  mkA2aPeerTokens = peers': lib.concatStringsSep "," (map mkA2aPeerToken peers');

  mkA2aTokenSecretName = peer: "hermes-agent-a2a-token-${peer}";

  mkPeerApiServerKeyName = peer: "hermes-agent-api-server-key-${peer}";

  mkBotPeers =
    peers':
    builtins.listToAttrs (
      map (
        peer:
        lib.nameValuePair peer.name {
          url = "https://${peer.name}.taila659a.ts.net:8642";
        }
      ) peers'
    );

  mkPeerKeyEnvs =
    peers':
    lib.concatStringsSep "\n" (
      map (
        peer:
        let
          secretName = mkPeerApiServerKeyName peer.name;
        in
        "HERMES_PEER_${lib.toUpper peer.name}_KEY=${config.sops.placeholder.${secretName}}"
      ) peers'
    );

  a2aBasePlugins = [
    "disk-cleanup"
    "hermes-lcm"
    "rtk-rewrite"
    "security-guidance"
  ];
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
  # minus the fleet/gateway/automation surface (matrix, bot_peers, platforms,
  # platform_toolsets, honcho memory, sops environmentFiles) on non-darwin
  # hosts. The A2A surface (server + peer mesh) is added only on darwin via
  # recursiveUpdate so the base config is unchanged elsewhere.
  services.hermes-agent =
    let
      basePlugins = a2aBasePlugins;
    in
    lib.recursiveUpdate
      {
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

          plugins.enabled = basePlugins;
        };
      }
      (
        lib.optionalAttrs pkgs.stdenv.isDarwin {
          environmentFiles = [
            config.sops.templates.hermes-agent-a2a-env.path
            config.sops.templates.hermes-agent-peer-keys-env.path
          ];

          settings = {
            platforms.a2a.enabled = true;
            a2a_agents = mkA2aAgents a2aOtherPeers;
            bot_peers = mkBotPeers a2aOtherPeers;
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
            plugins.enabled = basePlugins ++ [ "platforms/a2a-platform" ];
          };
        }
      );

  xdg.enable = true;
  sops = lib.mkIf pkgs.stdenv.isDarwin {
    secrets = builtins.listToAttrs (
      (map (p: lib.nameValuePair (mkA2aTokenSecretName p.name) { }) a2aPeers)
      ++ (map (p: lib.nameValuePair (mkPeerApiServerKeyName p.name) { }) a2aPeers)
    );

    templates = {
      hermes-agent-a2a-env = {
        content = ''
          A2A_HOST=0.0.0.0
          A2A_PORT=9900
          A2A_AGENT_NAME=${a2aHostName}
          A2A_PUBLIC_URL=https://${a2aHostName}.taila659a.ts.net:9900
          A2A_OWN_TOKEN=${config.sops.placeholder."${mkA2aTokenSecretName a2aHostName}"}
          A2A_PEER_TOKENS=${mkA2aPeerTokens a2aOtherPeers}
          A2A_TRUSTED_PEERS=${mkA2aTrustedPeers a2aOtherPeers}
        '';
      };
      hermes-agent-peer-keys-env = {
        content = toString (mkPeerKeyEnvs a2aOtherPeers);
      };
    };
  };
}
