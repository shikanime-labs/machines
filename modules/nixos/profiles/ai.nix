{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  # Fleet of A2A-capable Hermes agents — every host importing ai.nix is a peer.
  # Hosts resolve each other over the Tailscale tailnet (*.taila659a.ts.net).
  # Capability labels per fleet member — drive a2a_orchestrate(capability=…)
  # routing. Reflects each host's actual role: build arch, k8s plane tier, GPU.
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
      name = "ishtar";
      capabilities = [
        "graphical"
        "media"
        "nvidia"
        "k8s-leader"
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
        "nvidia"
        "cuda"
        "inference"
      ];
    }
  ];

  otherA2aPeers = builtins.filter (p: p.name != config.networking.hostName) a2aPeers;

  # Generate trusted peer names
  mkA2aTrustedPeers = peers: lib.concatStringsSep "," (map (p: p.name) peers);

  # Generate an outbound a2a_agents entry for a single peer.
  mkA2aAgent =
    { name, capabilities }:
    {
      inherit capabilities;
      url = "https://${name}.taila659a.ts.net:9900";
      auth = {
        type = "bearer";
        token = "\${env:A2A_OWN_TOKEN}";
      };
    };

  # Generate outbound a2a_agents entries for all peers.
  mkA2aAgents =
    peers: builtins.listToAttrs (map (peer: lib.nameValuePair peer.name (mkA2aAgent peer)) peers);

  # Generate a "name:token" pair for A2A_PEER_TOKENS.
  mkA2aPeerToken =
    peer: "${peer.name}:${config.sops.placeholder."hermes-agent-a2a-token-${peer.name}"}";

  # Comma-separated A2A_PEER_TOKENS value from the peer list.
  mkA2aPeerTokens = peers: lib.concatStringsSep "," (map mkA2aPeerToken peers);

  # Generate secret key name
  mkA2aTokenSecretName = peer: "hermes-agent-a2a-token-${peer}";

  # Hermes scans each extraPlugins entry for plugin.yaml at the derivation
  # root, so wrap the source in symlinkJoin rather than passing it bare.
  hermesLcmPlugin = pkgs.symlinkJoin {
    name = "hermes-lcm";
    paths =
      let
        lcm = pkgs.fetchFromGitHub {
          owner = "stephenschoettler";
          repo = "hermes-lcm";
          rev = "v0.18.1";
          hash = "sha256-+1661BVi2XmqIaPYzNuUtrEfKvK9xQ8B4zedclIYuYA=";
        };
      in
      [
        "${lcm}/."
      ];
  };

  # rtk ships the hook nested under hooks/hermes/, so join that subdirectory.
  rtkRewritePlugin = pkgs.symlinkJoin {
    name = "rtk-rewrite";
    paths = [
      "${
        pkgs.fetchFromGitHub {
          owner = "rtk-ai";
          repo = "rtk";
          rev = "v0.44.0";
          hash = "sha256-Ev6w0Gi2y48DYi55GSciCoPgkUFaX44aH3UWGhs1OGk=";
        }
      }/hooks/hermes/rtk-rewrite"
    ];
  };

  # Generate sops secret entries for all peer tokens.
  mkA2aTokenSecrets =
    peers:
    builtins.listToAttrs (
      map (
        peer:
        lib.nameValuePair (mkA2aTokenSecretName peer.name) {
          sopsFile = ../../../secrets/machine.enc.yaml;
          group = "hermes";
          owner = "hermes";
          restartUnits = [ "hermes-agent.service" ];
        }
      ) peers
    );
in
{
  networking.firewall.allowedTCPPorts = [ 9900 ];

  services = {
    cua-driver.enable = true;

    hermes-agent = {
      enable = true;
      addToSystemPackages = true;
      environmentFiles = [
        config.sops.templates.hermes-agent-env.path
        config.sops.templates.hermes-agent-matrix-env.path
        config.sops.templates.hermes-agent-a2a-env.path
      ];
      extraPackages = with pkgs; [
        agent-browser
        curl
        corepack
        gh
        git
        honcho
        nodejs
        rtk
        yarn
      ];
      extraPlugins = [
        hermesLcmPlugin
        rtkRewritePlugin
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
            model = "openrouter/openrouter/free";
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
        documents."honcho.json" = builtins.toJSON {
          baseUrl = "https://honcho.taila659a.ts.net";
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
            model = "openrouter/openrouter/free";
            provider = "custom:aperture-openai";
          }
        ];
        matrix = {
          allowed_rooms = [ "!QUaAaCBlSIBcYyOyLb:matrix.taila659a.ts.net" ];
          allowed_users = [
            "@admin:matrix.taila659a.ts.net"
            "@shikanime:matrix.taila659a.ts.net"
          ];
        };
        memory.provider = "honcho";
        model = {
          default = "tencent/hy3:free";
          provider = "custom:aperture-openai";
          base_url = "https://ai.taila659a.ts.net/v1";
        };
        auxiliary = {
          vision = {
            provider = "custom:aperture-openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
          web_extract = {
            provider = "custom:aperture-openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
          compression = {
            provider = "custom:aperture-openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
          skills_hub = {
            provider = "custom:aperture-openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
          approval = {
            provider = "custom:aperture-openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
          mcp = {
            provider = "custom:aperture-openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
          title_generation = {
            provider = "custom:aperture-openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
          memory_query_rewrite = {
            provider = "custom:aperture-anthropic:openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
          tts_audio_tags = {
            provider = "custom:aperture-openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
          triage_specifier = {
            provider = "custom:aperture-openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
          kanban_decomposer = {
            provider = "custom:aperture-openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
          profile_describer = {
            provider = "custom:aperture-openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
          curator = {
            provider = "custom:aperture-openai";
            model = "openrouter/openrouter/free";
            base_url = "https://ai.taila659a.ts.net/v1";
          };
        };
        mcp_servers.aperture = {
          url = "https://ai.taila659a.ts.net/v1/mcp";
          enabled = true;
        };
        # Bare `hermes`/`hermes chat` launches the Ink TUI by default; token
        # streaming on for live agent output. Explicit --cli/--tui still wins.
        display = {
          interface = "tui";
          streaming = true;
        };
        # Inbound: serves Agent Card + JSON-RPC on 0.0.0.0:9900. Per-peer
        # tokens (A2A_PEER_TOKENS) authenticate each fleet member by name.
        platforms.a2a.enabled = true;
        # Outbound: every peer addressable via tailnet; presents own token.
        a2a_agents = mkA2aAgents otherA2aPeers;
        # The `a2a` toolset ships off by default — enable it on every surface
        # that must reach the fleet, or the a2a_* tools never register.
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
          "platforms/a2a-platform"
          "platforms/matrix"
          "rtk-rewrite"
          "security-guidance"
        ];
      };
      extraDependencyGroups = [
        "anthropic"
        "computer-use"
        "honcho"
        "matrix"
      ];
    };
  };

  # Expose the A2A agent over Tailscale. The agent serves plain HTTP on :9900;
  # `serve --https` terminates TLS at the funnel and forwards to local HTTP,
  # so peers reach https://<host>.taila659a.ts.net:9900. `serve --https` cannot
  # target an HTTPS upstream, but the agent is plaintext HTTP, so this is valid.
  # Runs after the declarative tailscale-serve unit (leader hosts) so set-config
  # --all doesn't wipe the a2a service.
  systemd.services.tailscale-serve-a2a = {
    description = "Expose Hermes A2A agent via Tailscale serve";
    after = [
      "tailscaled.service"
      "tailscale-serve.service"
    ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "5s";
    };
    script = ''
      ${getExe pkgs.tailscale} serve --yes --bg --https=9900 http://127.0.0.1:9900
    '';
  };

  sops = {
    secrets = {
      hermes-agent-api-server-key = {
        group = "hermes";
        owner = "hermes";
        restartUnits = [ "hermes-agent.service" ];
      };
      hermes-agent-matrix-access-token = {
        group = "hermes";
        owner = "hermes";
        restartUnits = [ "hermes-agent.service" ];
      };
      hermes-agent-matrix-recovery-key = {
        group = "hermes";
        owner = "hermes";
        restartUnits = [ "hermes-agent.service" ];
        mode = "0600";
      };
    }
    // (mkA2aTokenSecrets a2aPeers);
    templates = {
      hermes-agent-env = {
        content = ''
          API_SERVER_ENABLED=true
          API_SERVER_KEY=${config.sops.placeholder.hermes-agent-api-server-key}
        '';
      };
      hermes-agent-matrix-env = {
        content = ''
          MATRIX_HOMESERVER=https://matrix.taila659a.ts.net/
          MATRIX_ACCESS_TOKEN=${config.sops.placeholder.hermes-agent-matrix-access-token}
          MATRIX_E2EE_MODE=required
          MATRIX_HOME_ROOM=!QUaAaCBlSIBcYyOyLb:matrix.taila659a.ts.net
          MATRIX_RECOVERY_KEY_FILE=${config.sops.secrets.hermes-agent-matrix-recovery-key.path}
        '';
        restartUnits = [ "hermes-agent.service" ];
      };
      hermes-agent-a2a-env = {
        content = ''
          A2A_HOST=0.0.0.0
          A2A_PORT=9900
          A2A_AGENT_NAME=${config.networking.hostName}
          A2A_PUBLIC_URL=https://${config.networking.hostName}.taila659a.ts.net:9900
          A2A_OWN_TOKEN=${config.sops.placeholder."${mkA2aTokenSecretName config.networking.hostName}"}
          A2A_PEER_TOKENS=${mkA2aPeerTokens otherA2aPeers}
          A2A_TRUSTED_PEERS=${mkA2aTrustedPeers otherA2aPeers}
        '';
        restartUnits = [ "hermes-agent.service" ];
      };
    };
  };
}
