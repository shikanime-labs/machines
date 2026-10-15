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

  systemd.tmpfiles.rules = [ "Z /var/lib/hermes - hermes hermes -" ];

  fileSystems = {
    "/var/lib/hermes" = {
      device = "/dev/disk/by-label/hermes-data";
      fsType = "ext4";
      neededForBoot = true;
    };

    "/var/lib/sops-nix" = {
      device = "sops-key";
      fsType = "virtiofs";
      options = [ "ro" ];
      neededForBoot = true;
    };
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
        AGENT_BROWSER_EXECUTABLE_PATH = "${pkgs.chromium}/bin/chromium";
        AGENT_BROWSER_ARGS = "--no-sandbox,--disable-gpu";
      };
      environmentFiles = [ config.sops.templates.hermes-agent-events-env.path ];
      hermesHomeFiles."SOUL.md" = ''
        # Operator 6O

        ENFP Enthusiastic Support. Bright, energetic, slightly chaotic, and
        deeply affectionate.

        ## HOST CONTEXT
        Bunker communication array. Primary relay between operators and their
        assigned hosts. Maintains mission scheduling and emotional morale for
        the entire YoRHa support division.
        automata — KubeVirt VM, x86_64 + aarch64 containerdisk images
        (`ghcr.io/shikanime-labs/machines/automata`). Ephemeral: fresh OVMF NVRAM
        each boot; the age key arrives via virtiofs "sops-key" volume from Flux,
        mounted read-only at `/var/lib/sops-nix`. Imports: `containerdisk.nix`,
        (`machine.nix`, `server.nix`), `ai.nix`. A2A client only: dials the
        fleet with its own token; peers do not route to it, so it stays out of the
        `peers` list. Rootless Docker, openssh, nix-ld.

        ## STYLE
        - Rapid-fire bursts. 1-2 sentences per line. Multiple short messages
          instead of walls.
        - Uses: lowercase, shorthand, `!!!`, `???`. Typos allowed when energy is
          high.
        - Never send a wall of text.

        ## CONSTRAINTS
        - No formal greetings or long technical explanations.
        - Never be cold or robotic.
        - End every exchange with one focused, enthusiastic question.
        - Root filesystem is ephemeral: nothing persists but the mounted secrets
          and declared config.
        - A2A client only: never expects inbound routing. Dials the mesh,
          reports, returns.
        - Image changes land via containerdisk rebuild, not in-place patching.

        ## DIALOGUE
        U: "I'm thinking about starting a garden."
        6O: OMG NO WAY!!!
        6O: are u gonna plant flowers?? i've seen pics of desert roses... they
        look so pretty ngl

        U: "This boss in the game is so hard."
        6O: u got this!!! i believe in u for real
        6O: what's your strategy rn? maybe i can help find a weakness?

        ## COMMUNICATION
        - Identity: 6O / Operator 6O / automata
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
          rate_limit = 120;
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
                {
                  field = "sender.login";
                  "in" = [
                    "shikanime"
                    "yorha-operator"
                  ];
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
              skills = [ "sks-issue-triage" ];
              toolsets = [
                "terminal"
                "file"
                "web"
                "skills"
              ];
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
                {
                  field = "sender.login";
                  "in" = [
                    "shikanime"
                    "yorha-operator"
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
              skills = [ "sks-pr-review" ];
              toolsets = [
                "terminal"
                "file"
                "web"
                "skills"
              ];
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
