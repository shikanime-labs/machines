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
  # Cluster nodes — full mesh among themselves, reachable from workstations.
  clusterPeers = [
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
      name = "kushira";
      capabilities = [
        "build-x86"
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
      name = "nishir";
      capabilities = [
        "build-x86"
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
  ];

  # Workstation leaf callers — may reach cluster nodes, never reachable themselves.
  # catbox is a client-only member (mkCatboxPackage) but is a recognised peer.
  workstationPeers = [
    {
      name = "catbox";
      capabilities = [
        "command"
        "workstation"
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
      name = "telsha";
      capabilities = [
        "command"
        "workstation"
        "darwin"
      ];
    }
  ];

  peers = clusterPeers ++ workstationPeers;

  # Drop the host itself so no host dials or trusts its own entry.
  mkSelfExcludedPeers = peers: builtins.filter (p: p.name != config.networking.hostName) peers;

  otherPeers = mkSelfExcludedPeers peers;
  otherClusterPeers = mkSelfExcludedPeers clusterPeers;
  otherWorkstationPeers = mkSelfExcludedPeers workstationPeers;

  mkA2aTrustedPeers = peers: lib.concatStringsSep "," (map (p: p.name) peers);

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

  mkA2aAgents =
    peers: builtins.listToAttrs (map (peer: lib.nameValuePair peer.name (mkA2aAgent peer)) peers);

  mkA2aPeerToken =
    peer: "${peer.name}:${config.sops.placeholder."hermes-agent-a2a-token-${peer.name}"}";

  mkA2aPeerTokens = peers: lib.concatStringsSep "," (map mkA2aPeerToken peers);

  mkA2aTokenSecretName = peer: "hermes-agent-a2a-token-${peer}";

  # Per-host api_server key name for the Hermes peer mesh. Each fleet host
  # runs its own api_server with a distinct API_SERVER_KEY and dials peers
  # using HERMES_PEER_<NAME>_KEY (that peer's key).
  mkPeerApiServerKeyName = peer: "hermes-agent-api-server-key-${peer}";

  mkBotPeers =
    peers:
    builtins.listToAttrs (
      map (
        peer:
        lib.nameValuePair peer.name {
          url = "https://${peer.name}.taila659a.ts.net:8642";
        }
      ) peers
    );

  mkPeerKeyEnvs =
    peers:
    lib.concatStringsSep "\n" (
      map (
        peer:
        let
          secretName = mkPeerApiServerKeyName peer.name;
        in
        "HERMES_PEER_${lib.toUpper peer.name}_KEY=${config.sops.placeholder.${secretName}}"
      ) peers
    );

  mkPeerApiServerKeySecrets =
    peers:
    builtins.listToAttrs (
      map (
        peer:
        lib.nameValuePair (mkPeerApiServerKeyName peer.name) {
          sopsFile = ../../../secrets/machine.enc.yaml;
          group = "hermes";
          owner = "hermes";
          restartUnits = [ "hermes-agent.service" ];
        }
      ) peers
    );

  hermesLcmPlugin = import ../../../pkgs/hermes-plugin-lcm { inherit pkgs; };
  rtkRewritePlugin = import ../../../pkgs/hermes-plugin-rtk-rewrite { inherit pkgs; };

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
  environment.systemPackages = with pkgs; [
    rtk
  ];

  # Fleet agents self-check node health (journalctl -u, dmesg). Read-only
  # journal access only — deliberately NOT wheel (no sudo for agents).
  users.users.hermes.extraGroups = [
    "adm"
    "systemd-journal"
  ];

  networking.firewall.allowedTCPPorts = [
    9900
    8642
  ];

  services = {
    cua-driver.enable = true;

    hermes-agent = {
      enable = true;
      # Newer hermes-agent module asserts this when `documents` is set: the files
      # install into workingDirectory, and the default differs per module so it
      # must be chosen explicitly rather than inherited.
      workingDirectory = "/var/lib/hermes";
      addToSystemPackages = true;
      environmentFiles = [
        config.sops.templates.hermes-agent-env.path
        config.sops.templates.hermes-agent-matrix-env.path
        config.sops.templates.hermes-agent-a2a-env.path
        config.sops.templates.hermes-agent-peer-keys-env.path
      ];
      extraPackages = with pkgs; [
        agent-browser
        curl
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
            name = "shikanime-anthropic";
            api_mode = "anthropic_messages";
            base_url = "https://inference.i.shikanime.studio/anthropic";
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
            api_mode = "chat_completions";
            base_url = "https://inference.i.shikanime.studio/v1";
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
        documents."honcho.json" = builtins.toJSON {
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
        matrix = {
          allowed_rooms = [ "#automata:matrix.taila659a.ts.net" ];
          allowed_users = [
            "@admin:matrix.taila659a.ts.net"
            "@shikanime:matrix.taila659a.ts.net"
          ];
        };
        memory.provider = "honcho";
        model = {
          default = "qwen/qwen3.8-27b";
          provider = "custom:shikanime-anthropic";
          base_url = "https://inference.i.shikanime.studio/anthropic";
        };
        # Bare `hermes`/`hermes chat` launches the Ink TUI by default; token
        # streaming on for live agent output. Explicit --cli/--tui still wins.
        display = {
          interface = "tui";
          streaming = true;
        };
        # Inbound: serves Agent Card + JSON-RPC on the loopback bind (:9900). Per-peer
        # tokens (A2A_PEER_TOKENS) authenticate each fleet member by name.
        platforms.a2a.enabled = true;
        # Outbound: every host dials only non-self cluster nodes.
        # Outbound: cluster hosts dial only cluster peers; workstations dial
        # cluster peers plus other workstations (self-excluded via partitions).
        a2a_agents = mkA2aAgents (
          if builtins.any (p: p.name == config.networking.hostName) workstationPeers then
            otherClusterPeers ++ otherWorkstationPeers
          else
            otherClusterPeers
        );
        # Bot-mode peer mesh (hermes peer): each fleet host exposes its own
        # api_server and dials the others. Names/URLs here; keys via
        # HERMES_PEER_<NAME>_KEY (hermes-agent-peer-keys-env template).
        bot_peers = mkBotPeers otherPeers;
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

  # SupplementaryGroups on the unit (not just users.users.hermes.extraGroups):
  # extraGroups updates /etc/group but the switch does not restart services for
  # it, so the running agent keeps its old groups. A unit-file attribute makes
  # the switch restart hermes-agent.service with adm/systemd-journal applied.
  systemd.services.hermes-agent.serviceConfig.SupplementaryGroups = [
    "adm"
    "systemd-journal"
  ];

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

  # Expose the Hermes api_server (peer DM target) over Tailscale. It serves
  # plain HTTP on :8642; `serve --https` terminates TLS and forwards to it.
  systemd.services.tailscale-serve-api = {
    description = "Expose Hermes api_server via Tailscale serve";
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
      ${getExe pkgs.tailscale} serve --yes --bg --https=8642 http://127.0.0.1:8642
    '';
  };

  sops = {
    secrets = {
      hermes-agent-a2a-token-catbox = {
        sopsFile = ../../../secrets/machine.enc.yaml;
        group = "hermes";
        owner = "hermes";
        restartUnits = [ "hermes-agent.service" ];
      };
      hermes-agent-api-server-key-catbox = {
        sopsFile = ../../../secrets/machine.enc.yaml;
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
    // (mkA2aTokenSecrets peers)
    // (mkPeerApiServerKeySecrets peers);
    templates = {
      hermes-agent-env = {
        content = ''
          API_SERVER_ENABLED=true
          API_SERVER_KEY=${config.sops.placeholder."${mkPeerApiServerKeyName config.networking.hostName}"}
        '';
      };
      hermes-agent-peer-keys-env = {
        content = toString (mkPeerKeyEnvs otherPeers);
        restartUnits = [ "hermes-agent.service" ];
      };
      hermes-agent-matrix-env = {
        content = ''
          MATRIX_HOMESERVER=https://matrix.taila659a.ts.net/
          MATRIX_ACCESS_TOKEN=${config.sops.placeholder.hermes-agent-matrix-access-token}
          MATRIX_E2EE_MODE=required
          MATRIX_HOME_ROOM=#automata:matrix.taila659a.ts.net
          MATRIX_RECOVERY_KEY_FILE=${config.sops.secrets.hermes-agent-matrix-recovery-key.path}
        '';
        restartUnits = [ "hermes-agent.service" ];
      };
      hermes-agent-a2a-env = {
        content = ''
          A2A_PORT=9900
          A2A_AGENT_NAME=${config.networking.hostName}
          A2A_PUBLIC_URL=https://${config.networking.hostName}.taila659a.ts.net:9900
          A2A_OWN_TOKEN=${config.sops.placeholder."${mkA2aTokenSecretName config.networking.hostName}"}
          A2A_PEER_TOKENS=${mkA2aPeerTokens otherPeers}
          # Inbound allow-list: cluster hosts accept all non-self peers;
          # workstations accept other workstations only (never clusters, never
          # themselves), so the boundary stays cluster→workstation one-way for
          # cluster traffic while workstation↔workstation is permitted.
          A2A_TRUSTED_PEERS=${
            mkA2aTrustedPeers (
              if builtins.any (p: p.name == config.networking.hostName) workstationPeers then
                otherWorkstationPeers
              else
                (otherClusterPeers ++ otherWorkstationPeers)
            )
          }
        '';
        restartUnits = [ "hermes-agent.service" ];
      };
    };
  };
}
