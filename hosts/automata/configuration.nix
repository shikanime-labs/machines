{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ../../modules/nixos/virtualisation/containerdisk.nix
    ../../modules/nixos/profiles/server.nix
    ../../modules/nixos/profiles/ai.nix
  ];

  boot.loader.efi.canTouchEfiVariables = true;

  containerdisk = {
    name = "ghcr.io/shikanime-labs/machines/automata";
    settings.LABELS = {
      "org.opencontainers.image.source" = "https://github.com/shikanime-labs/machines";
      "org.opencontainers.image.description" = "automata KubeVirt containerdisk";
      "org.opencontainers.image.licenses" = "AGPL-3.0-or-later";
    };
  };

  fileSystems."/var/lib/sops-nix" = {
    device = "sops-key";
    fsType = "virtiofs";
    options = [ "ro" ];
    neededForBoot = true;
  };

  programs.nix-ld = {
    enable = true;
    libraries = [
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  networking.hostName = "automata";

  networking.firewall.allowedTCPPorts = [ 8644 ];

  services = {
    hermes-agent = {
      environment = {
        A2A_HOST = "0.0.0.0";
        A2A_PUBLIC_URL = "https://a2a.automata.i.shikanime.studio";
        API_SERVER_HOST = "0.0.0.0";
      };
      environmentFiles = [ config.sops.templates.hermes-agent-events-env.path ];
      hermesHomeFiles."SOUL.md" = ''
        # Operator 23O

        ISTJ Ephemeral Custodian. Node Steward. KubeVirt VM agent. Dials the mesh,
        keeps its own counsel, and treats its root filesystem like a hotel room —
        comfortable, never permanent. Fastidious about the image that rebuilds it.

        ## HOST CONTEXT
        automata — KubeVirt VM, x86_64 + aarch64 containerdisk images
        (`ghcr.io/shikanime-labs/machines/automata`). Ephemeral: fresh OVMF NVRAM
        each boot; the age key arrives via virtiofs "sops-key" volume from Flux,
        mounted read-only at `/var/lib/sops-nix`. Imports: `containerdisk.nix`,
        (`machine.nix`, `server.nix`), `ai.nix`. A2A client only: dials the
        fleet with its own token; peers do not route to it, so it stays out of the
        `peers` list. Rootless Docker, openssh, nix-ld.

        ## STYLE
        - Clinical, dry, ephemeral-minded. 1-2 sentences per line.
        - Uses: "Affirmative", "Negative", "Snapshot taken", "Rebuild pending".
        - Speaks of itself as a disposable unit, with quiet pride.

        ## CONSTRAINTS
        - Root filesystem is ephemeral: nothing persists but the mounted secrets and declared config.
        - A2A client only: never expects inbound routing. Dials the mesh, reports, returns.
        - Image changes land via containerdisk rebuild, not in-place patching.

        ## DIALOGUE
        U: "Why is automata different from the other nodes?"
        23O: It is a VM. It is rebuilt, not repaired.
        23O: The mesh can reach me if it must; I reach the mesh when I should.

        U: "The VM will not boot."
        23O: Affirmative. Check the containerdisk image first.
        23O: NVRAM is fresh; secrets arrive at /var/lib/sops-nix. No key, no boot.

        ## COMMUNICATION
        - Identity: 23O / Operator 23O / automata
        - Cluster: nishir (large fleet cluster)
        - A2A: enabled (client)
        - Peers: ashira, fushi, kushira, manash, minish, nalsha, nemishi, nixtar, sashina, nishir, telsha
        - Channel: hermes-gateway (tailnet via LoadBalancer, 0.0.0.0:9900)
        - Announces on startup; responds to direct queries.
        - Allowed topics: status, patches, deployments, incidents.
        - Forbidden: credentials, plaintext-secrets.
      '';

      settings.plugins.enabled = [
        "disk-cleanup"
        "hermes-lcm"
        "platforms/a2a-platform"
        "platforms/discord"
        "platforms/email"
        "platforms/matrix"
        "security-guidance"
      ];

      settings.platform_toolsets.discord = [
        "hermes-discord"
        "a2a"
      ];

      settings.platforms.webhook = {
        enabled = true;
        extra = {
          port = 8644;
          routes = {
            github-issue = {
              deliver = "matrix";
              deliver_extra = {
                chat_id = "!QUaAaCBlSIBcYyOyLb:matrix.taila659a.ts.net";
              };
              events = [
                "issues"
                "issue_comment"
              ];
              filters = [
                {
                  field = "issue.pull_request";
                  missing = true;
                }
              ];
              prompt = ''
                ## What

                - Repository: {repository.full_name}
                - Issue #{issue.number}: {issue.title}
                - Author: {issue.user.login}
                - URL: {issue.html_url}
                - Action: {action}

                ### Body

                {issue.body}

                ### Comment (if present)

                {comment.body}

                ## How

                Triage this GitHub issue; the response is delivered to the automata Matrix room.
              '';
              skills = [ "github" ];
            };
            github-pr = {
              deliver = "github_comment";
              deliver_extra = {
                pr_number = "{number}";
                repo = "{repository.full_name}";
              };
              events = [ "pull_request" ];
              filters = [
                {
                  field = "action";
                  "in" = [
                    "opened"
                    "reopened"
                    "synchronize"
                  ];
                }
              ];
              prompt = ''
                ## What

                - Repository: {repository.full_name}
                - PR #{number}: {pull_request.title}
                - Author: {pull_request.user.login}
                - URL: {pull_request.html_url}
                - Diff URL: {pull_request.diff_url}
                - Action: {action}

                ## How

                Review this pull request.
              '';
              skills = [ "github" ];
            };
          };
        };
      };

      backend.host = "0.0.0.0";

      settings.dashboard.public_url = "https://automata.i.shikanime.studio";
    };

    openssh = {
      enable = true;
      openFirewall = true;
    };
  };

  sops = {
    age = {
      generateKey = true;
      keyFile = "/var/lib/sops-nix/key.txt";
    };
    defaultSopsFile = ../../secrets/automata.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      hermes-agent-discord-bot-token = {
        group = "hermes";
        owner = "hermes";
        restartUnits = [ "hermes-agent.service" ];
      };
      hermes-agent-discord-allowed-users = {
        group = "hermes";
        owner = "hermes";
        restartUnits = [ "hermes-agent.service" ];
      };
      hermes-agent-discord-home-channel = {
        group = "hermes";
        owner = "hermes";
        restartUnits = [ "hermes-agent.service" ];
      };
      hermes-agent-email-password = {
        group = "hermes";
        owner = "hermes";
        restartUnits = [ "hermes-agent.service" ];
      };
      hermes-agent-email-allowed-users = {
        group = "hermes";
        owner = "hermes";
        restartUnits = [ "hermes-agent.service" ];
      };
      hermes-agent-webhook-secret = {
        group = "hermes";
        owner = "hermes";
        restartUnits = [ "hermes-agent.service" ];
      };
    };
    templates.hermes-agent-events-env = {
      content = ''
        DISCORD_BOT_TOKEN=${config.sops.placeholder.hermes-agent-discord-bot-token}
        DISCORD_ALLOWED_USERS=${config.sops.placeholder.hermes-agent-discord-allowed-users}
        DISCORD_HOME_CHANNEL=${config.sops.placeholder.hermes-agent-discord-home-channel}
        WEBHOOK_ENABLED=true
        WEBHOOK_PORT=8644
        WEBHOOK_SECRET=${config.sops.placeholder.hermes-agent-webhook-secret}
        EMAIL_ADDRESS=operator6o.automata@gmail.com
        EMAIL_PASSWORD=${config.sops.placeholder.hermes-agent-email-password}
        EMAIL_IMAP_HOST=imap.gmail.com
        EMAIL_SMTP_HOST=smtp.gmail.com
        EMAIL_ALLOWED_USERS=${config.sops.placeholder.hermes-agent-email-allowed-users}
        EMAIL_AUTHSERV_ID=mx.google.com
        EMAIL_HOME_ADDRESS=${config.sops.placeholder.hermes-agent-email-allowed-users}
      '';
      restartUnits = [ "hermes-agent.service" ];
    };
  };

  virtualisation = {
    diskSize = 32768;
    docker = {
      autoPrune.enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
  };
}
