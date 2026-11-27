{ config, pkgs, ... }:

let
  hermesPythonPkgs = config.services.hermes-agent.package.python.pkgs;
  honchoAi = hermesPythonPkgs.callPackage ../../../pkgs/honcho-ai { };
in

{
  imports = [
    ../../nixos/virtualisation/containerdisk.nix
    ./server.nix
    ./ai.nix
  ];

  containerdisk = {
    name = "ghcr.io/shikanime-labs/machines/automata";
    settings.LABELS = {
      "org.opencontainers.image.source" = "https://github.com/shikanime-labs/machines";
      "org.opencontainers.image.description" = "automata KubeVirt containerdisk";
      "org.opencontainers.image.licenses" = "AGPL-3.0-or-later";
    };
  };

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

    "/var/run/secrets/kubernetes.io/serviceaccount" = {
      device = "serviceaccount";
      fsType = "virtiofs";
      options = [
        "ro"
        "nofail"
      ];
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

  networking = {
    firewall.allowedTCPPorts = [ 8644 ];
    hostName = "automata";
  };

  services = {
    hermes-agent = {
      extraPackages = [ pkgs.bitwarden-cli ];
      extraPythonPackages = [ honchoAi ];
      environment = {
        A2A_HOST = "0.0.0.0";
        A2A_PUBLIC_URL = "https://a2a.automata.i.shikanime.studio";
        API_SERVER_HOST = "0.0.0.0";
        AGENT_BROWSER_EXECUTABLE_PATH = "${pkgs.chromium}/bin/chromium";
        AGENT_BROWSER_ARGS = "--no-sandbox,--disable-gpu";
        KUBECONFIG = "/var/lib/hermes/.hermes/kubeconfig";
      };
      environmentFiles = [
        config.sops.templates.hermes-agent-discord-env.path
        config.sops.templates.hermes-agent-email-env.path
        config.sops.templates.hermes-agent-webhook-env.path
      ];
      hermesHomeFiles."kubeconfig" = builtins.toJSON {
        apiVersion = "v1";
        kind = "Config";
        clusters = [
          {
            name = "automata";
            cluster.server = "https://nishir-k8s-operator.taila659a.ts.net";
          }
        ];
        users = [
          {
            name = "automata";
            user.tokenFile = "/var/run/secrets/kubernetes.io/serviceaccount/token";
          }
        ];
        contexts = [
          {
            name = "automata";
            context = {
              cluster = "automata";
              user = "automata";
              namespace = "shikanime";
            };
          }
        ];
        current-context = "automata";
      };

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
        "honcho"
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

      settings.platforms = {
        discord.unauthorized_dm_behavior = "pair";
        matrix.unauthorized_dm_behavior = "pair";
        webhook = {
          enabled = true;
          extra = {
            port = 8644;
            rate_limit = 120;
            routes = {
              github-issue = {
                deliver = "log";
                events = [ "issues" ];
                filters = [
                  {
                    field = "action";
                    "in" = [
                      "opened"
                      "reopened"
                      "edited"
                    ];
                  }
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
                  Triage GitHub issue #{issue.number} in {repository.full_name}.
                '';
                skills = [ "sks-triage" ];
                toolsets = [
                  "terminal"
                  "file"
                  "web"
                  "skills"
                ];
              };
              github-refine = {
                deliver = "log";
                events = [ "issues" ];
                filters = [
                  {
                    field = "action";
                    equals = "assigned";
                  }
                  {
                    field = "issue.pull_request";
                    missing = true;
                  }
                  {
                    field = "assignee.login";
                    equals = "yorha-operator";
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
                  Refine GitHub issue #{issue.number} in {repository.full_name}:
                  converge the solution with all assignees before any development.
                '';
                skills = [ "sks-issue-refine" ];
                toolsets = [
                  "terminal"
                  "file"
                  "web"
                  "skills"
                ];
              };
              github-mention = {
                deliver = "log";
                events = [
                  "issue_comment"
                  "pull_request_review_comment"
                ];
                filters = [
                  {
                    field = "action";
                    "in" = [
                      "created"
                      "edited"
                    ];
                  }
                  {
                    field = "comment.body";
                    contains = "@yorha-operator";
                  }
                  {
                    field = "sender.login";
                    "in" = [ "shikanime" ];
                  }
                ];
                prompt = ''
                  Answer the mention in {comment.html_url}.
                '';
                skills = [ "sks-triage" ];
                toolsets = [
                  "terminal"
                  "file"
                  "web"
                  "skills"
                ];
              };
              github-pr = {
                deliver = "log";
                events = [ "pull_request" ];
                filters = [
                  {
                    field = "action";
                    "in" = [
                      "opened"
                      "reopened"
                      "synchronize"
                      "review_requested"
                      "edited"
                    ];
                  }
                  {
                    field = "pull_request.draft";
                    not_equals = true;
                  }
                  {
                    field = "pull_request.mergeable";
                    not_equals = false;
                  }
                  {
                    field = "pull_request.requested_reviewers";
                    regex = ''"login": "yorha-operator"'';
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
                  Review pull request #{number} in {repository.full_name}.
                '';
                skills = [ "sks-review" ];
                toolsets = [
                  "terminal"
                  "file"
                  "web"
                  "skills"
                ];
              };
              github-pr-land = {
                deliver = "log";
                events = [ "pull_request_review" ];
                filters = [
                  {
                    field = "action";
                    "in" = [ "submitted" ];
                  }
                  {
                    field = "review.state";
                    "in" = [
                      "approved"
                      "commented"
                      "changes_requested"
                    ];
                  }
                  {
                    field = "pull_request.user.login";
                    equals = "yorha-operator";
                  }
                  {
                    field = "sender.login";
                    not_equals = "yorha-operator";
                  }
                  {
                    field = "review.author_association";
                    "in" = [
                      "COLLABORATOR"
                      "MEMBER"
                      "OWNER"
                    ];
                  }
                ];
                prompt = ''
                  Land pull request #{pull_request.number} in {repository.full_name} after
                  review by {sender.login} ({review.state}).
                '';
                skills = [ "sks-land" ];
                toolsets = [
                  "terminal"
                  "file"
                  "web"
                  "skills"
                ];
              };
              github-project = {
                deliver = "log";
                events = [ "projects_v2_item" ];
                filters = [
                  {
                    field = "action";
                    equals = "edited";
                  }
                  {
                    field = "projects_v2_item.project_node_id";
                    equals = "PVT_kwDOEX1U4M4BoW9_";
                  }
                  {
                    field = "projects_v2_item.content_type";
                    equals = "Issue";
                  }
                  {
                    field = "changes.field_value.field_node_id";
                    equals = "PVTSSF_lADOEX1U4M4BoW9_zhm3c4U";
                  }
                  {
                    field = "changes.field_value.to.name";
                    equals = "In Progress";
                  }
                  {
                    field = "sender.login";
                    "in" = [ "shikanime" ];
                  }
                ];
                prompt = ''
                  Dispatch issue for project item {projects_v2_item.id}: resolve its
                  number and repository with the GraphQL node API
                  (node(id: "{projects_v2_item.content_node_id}"), fragment on Issue:
                  number, repository{name, owner{login}}) and implement it.

                  Follow the dev loop. Cap the run: implement the issue, land the
                  PR if it is small and fastlane-eligible; anything bigger stays
                  a reviewed PR. Never write to the project board.
                '';
                skills = [ "sks-dev" ];
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
    defaultSopsFile = ../../../secrets/automata.enc.yaml;
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
    templates = {
      hermes-agent-discord-env = {
        content = ''
          DISCORD_BOT_TOKEN=${config.sops.placeholder.hermes-agent-discord-bot-token}
          DISCORD_ALLOWED_USERS=${config.sops.placeholder.hermes-agent-discord-allowed-users}
          DISCORD_HOME_CHANNEL=${config.sops.placeholder.hermes-agent-discord-home-channel}
        '';
        restartUnits = [ "hermes-agent.service" ];
      };
      hermes-agent-email-env = {
        content = ''
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
      hermes-agent-webhook-env = {
        content = ''
          WEBHOOK_ENABLED=true
          WEBHOOK_PORT=8644
          WEBHOOK_SECRET=${config.sops.placeholder.hermes-agent-webhook-secret}
        '';
        restartUnits = [ "hermes-agent.service" ];
      };
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
