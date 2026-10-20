{
  config,
  osConfig,
  pkgs,
  ...
}:

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
    openssh = {
      enable = true;
      openFirewall = true;
    };
  };

  home-manager.users.hermes.services = {
    hermes-agent = {
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
            cluster = {
              server = "https://nishir-k8s-operator.taila659a.ts.net";
              certificate-authority = "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt";
            };
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

      hermesHomeFiles."cron/jobs.json" = builtins.toJSON {
        jobs = [
          {
            id = "164a6977d1ea";
            name = "daily-grafana-alert-triage";
            enabled = true;
            deliver = "local";
            schedule = {
              kind = "cron";
              expr = "0 0 * * *";
            };
            skills = [
              "sks-grafana-audit"
              "sks-issue"
              "sks-commit"
              "sks-pr"
              "sks-fastlane"
            ];
            prompt = ''
              Daily alert triage for the nishir fleet.

              1. Read firing alerts (no auth, pod network):
                 curl -s http://vmalertmanager-vmks-victoria-metrics-k8s-stack.monitoring-system.svc:9093/api/v2/alerts
                 Parse with python3. Record alertname, labels, annotations, startsAt.
              2. Note alerts resolved since the last sweep; close nothing automatically.
              3. Before reporting: honcho_search "grafana alert triage" and
                 honcho_reasoning "What alert-handling lessons from previous runs apply
                 here?" - apply recurring context (known flapping alerts, fastlane
                 patterns that worked), then honcho_conclude write one line per durable
                 lesson.
            '';
          }
          {
            id = "58e6ae639a88";
            name = "daily-flux-failure-triage";
            enabled = true;
            deliver = "local";
            schedule = {
              kind = "cron";
              expr = "15 0 * * *";
            };
            skills = [
              "sks-flux-audit"
              "sks-issue"
              "sks-commit"
              "sks-pr"
              "sks-fastlane"
            ];
            prompt = ''
              Daily Flux health triage for the nishir fleet.

              1. Read cluster state with kubectl (context automata, credentials from the projected
                 service-account volume at /var/run/secrets/kubernetes.io/serviceaccount):
                 kubectl get kustomizations -A -o wide and kubectl get helmreleases -A -o wide,
                 plus -o json for conditions. List every object whose Ready condition is False,
                 with message and source revision.
              2. Before reporting: honcho_search "flux triage" and honcho_context - reuse
                 recurring context (objects that chronically fail, suspended-object
                 policy, fastlane fixes that landed), then honcho_conclude write one
                 line per durable lesson.
            '';
          }
          {
            id = "c2e85641351b";
            name = "daily-github-actions-failure-triage";
            enabled = true;
            deliver = "local";
            schedule = {
              kind = "cron";
              expr = "30 0 * * *";
            };
            skills = [
              "sks-github-actions-audit"
              "sks-issue"
              "sks-commit"
              "sks-pr"
              "sks-fastlane"
            ];
            prompt = ''
              Daily CI failure sweep for shikanime-labs, shikanime-studio and
              cloud-pi-native.

              1. In cloud-pi-native only sweep repos with open PRs or issues authored by
                 shikanime or yorha-operator (gh search prs/issues --owner
                 cloud-pi-native --author shikanime --state open, then the same with
                 --author yorha-operator; one flag per run, union the results);
                 file issues only in those repos.
              2. Before reporting: honcho_search "CI failure sweep" and honcho_context -
                 reuse recurring context (workflows that flap, fastlane fixes that
                 landed, re-arm quirks), then honcho_conclude write one line per
                 durable lesson.
            '';
          }
          {
            id = "3453978b1312";
            name = "weekly-a2a-cluster-efficiency-audit";
            enabled = true;
            deliver = "local";
            schedule = {
              kind = "cron";
              expr = "0 1 * * 1";
            };
            skills = [ "sks-issue" ];
            prompt = ''
              Weekly cluster-efficiency brainstorm with the A2A fleet.

              1. Discover peers with a2a_list. Every reachable peer participates; note unreachable
                 ones and continue.
              2. One a2a_call per peer: "From your vantage point, what is the single
                 highest-leverage efficiency improvement in the fleet right now (compute, storage,
                 cost, redundancy)?" Each answer must state: observation, evidence, proposed change,
                 expected saving.
              3. Aggregate: dedup overlapping proposals, rank by leverage / effort. Drop proposals
                 already filed or rejected: gh issue list -R shikanime-labs/manifests, open and
                 recently closed.
              4. File the top proposals (max 3) as issues in shikanime-labs/manifests, one per proposal, crediting the contributing agents in the body.
                 Proposals only - no PRs from this job.
              5. Before reporting: honcho_search "cluster efficiency" and honcho_reasoning
                 "Which efficiency lessons from previous audits still apply?" - drop proposals
                 already tried and rejected, then honcho_conclude write one line per durable
                 lesson.
            '';
          }
          {
            id = "adfc09a25ae9";
            name = "daily-documentation-sync";
            enabled = true;
            deliver = "local";
            schedule = {
              kind = "cron";
              expr = "45 0 * * *";
            };
            skills = [
              "sks-issue"
              "sks-commit"
              "sks-pr"
              "sks-fastlane"
            ];
            prompt = ''
              Daily documentation verification for docs.shikanime.studio.

              1. Clone https://github.com/shikanime-studio/websites (depth 1) to /tmp; the site is
                 apps/docs, pages under apps/docs/docs/<section>/, sidebars.ts, product table.
              2. Verify factual claims against ground truth - deployed manifests (clone
                 https://github.com/shikanime-labs/manifests depth 1), live cluster state (kubectl,
                 context automata), repo git logs - never from memory. Stale references are the norm.
                 Drift between a documented service (name, hostname, port, image) and its manifest is
                 a defect.
              3. File new drift in shikanime-studio/websites:
                 page, claim, ground truth, source links. Assignee yorha-operator if eligible.
              4. Small factual fixes only (typo, stale name, corrected port): fastlane.
                 Deploy stays manual - never wrangler deploy from this job.
              5. Before reporting: honcho_search "documentation drift" and honcho_context -
                 reuse recurring context (pages that keep drifting, ground-truth
                 sources that settled past drift), then honcho_conclude write one
                 line per durable lesson.
            '';
          }
          {
            id = "94e210d7e1fd";
            name = "daily-security-audit";
            enabled = true;
            deliver = "local";
            schedule = {
              kind = "cron";
              expr = "15 1 * * *";
            };
            skills = [
              "sks-security-audit"
              "sks-issue"
              "sks-commit"
              "sks-pr"
              "sks-fastlane"
            ];
            prompt = ''
              Daily security audit for shikanime-labs, shikanime-studio and
              cloud-pi-native.

              1. In cloud-pi-native only file issues for repos with open PRs or issues
                 authored by shikanime or yorha-operator (gh search prs/issues --owner
                 cloud-pi-native --author shikanime --state open, then the same with
                 --author yorha-operator; one flag per run, union the results);
                 note other alerts without filing.
              2. Never close or dismiss alerts from this job; resolved alerts are noted
                 only.
              3. Before reporting: honcho_search "security audit" and honcho_context -
                 reuse recurring context (alert types that recur, remediations already
                 in flight, duplicates the redteam run already exploited), then
                 honcho_conclude write one line per durable lesson.
            '';
          }
          {
            id = "2cf2e9db64d5";
            name = "daily-security-redteam";
            enabled = true;
            deliver = "local";
            schedule = {
              kind = "cron";
              expr = "15 2 * * *";
            };
            skills = [
              "sks-redteam"
              "sks-issue"
              "sks-commit"
              "sks-pr"
              "sks-fastlane"
            ];
            prompt = ''
              Daily offensive security probe for shikanime-labs and shikanime-studio.

              1. Before reporting: honcho_reasoning "Which attack paths from previous probes
                 remain unpatched?" - re-verify the top open items instead of rediscovering
                 them, then honcho_conclude write one line per durable lesson.
            '';
          }
          {
            id = "f077dc14361e";
            name = "daily-renovate-landing";
            enabled = true;
            deliver = "local";
            schedule = {
              kind = "cron";
              expr = "30 2 * * *";
            };
            skills = [
              "sks-renovate-sweep"
              "sks-issue"
              "sks-land"
            ];
            prompt = ''
              Daily landing pass over open renovate PRs across shikanime-labs,
              shikanime-studio and cloud-pi-native.

              1. In cloud-pi-native only land repos with open PRs authored by
                 shikanime or yorha-operator (gh search prs --owner cloud-pi-native
                 --author shikanime --state open, then the same with --author
                 yorha-operator; one flag per run, union the results); skip the rest.
              2. Before reporting: honcho_search "renovate sweep" and honcho_context -
                 reuse recurring context (PRs reported in previous runs and why they are
                 stuck, repos with known renovate CI quirks), then honcho_conclude write
                 one line per durable lesson.
            '';
          }
          {
            id = "84f435ca5d9e";
            name = "daily-github-triage";
            enabled = true;
            deliver = "local";
            schedule = {
              kind = "cron";
              expr = "30 1 * * *";
            };
            skills = [
              "sks-triage"
              "sks-issue"
            ];
            prompt = ''
              Daily GitHub triage for shikanime-labs, shikanime-studio and
              cloud-pi-native.

              1. In cloud-pi-native only triage repos with open PRs or issues authored by
                 shikanime or yorha-operator (gh search prs/issues --owner
                 cloud-pi-native --author shikanime --state open, then the same with
                 --author yorha-operator; one flag per run, union the results);
                 leave the rest untouched.
              2. Before reporting: honcho_search "GitHub triage" and honcho_context -
                 reuse recurring context (systemic findings already filed, items a
                 previous run left pending on purpose), then honcho_conclude write
                 one line per durable lesson.
            '';
          }
          {
            id = "886e812cac7f";
            name = "daily-github-cleanup";
            enabled = true;
            deliver = "local";
            schedule = {
              kind = "cron";
              expr = "45 1 * * *";
            };
            skills = [ "sks-gc" ];
            prompt = ''
              Daily GitHub cleanup for shikanime-labs, shikanime-studio and
              cloud-pi-native.

              1. In cloud-pi-native only touch repos with open PRs or issues authored by
                 shikanime or yorha-operator (gh search prs/issues --owner
                 cloud-pi-native --author shikanime --state open, then the same with
                 --author yorha-operator; one flag per run, union the results);
                 never touch any other branch there.
              2. Before reporting: honcho_search "stale branch cleanup" and honcho_context -
                 reuse recurring context (branches a previous run flagged blocked and why),
                 then honcho_conclude write one line per durable lesson.
            '';
          }
          {
            id = "3c7ce2a4c3e1";
            name = "daily-github-notification-sweep";
            enabled = true;
            deliver = "local";
            schedule = {
              kind = "cron";
              expr = "0 2 * * *";
            };
            skills = [
              "sks-github-notif-sweep"
              "sks-triage"
            ];
            prompt = ''
              Daily sweep of unread GitHub notifications for shikanime-labs and
              shikanime-studio.

              1. Before reporting: honcho_search "notification sweep" and honcho_context -
                 reuse recurring context (threads a previous run answered, noise
                 patterns to skip), then honcho_conclude write one line per durable
                 lesson.
            '';
          }
          {
            id = "07ace7423c04";
            name = "daily-kubernetes-events-triage";
            enabled = true;
            deliver = "local";
            schedule = {
              kind = "cron";
              expr = "45 2 * * *";
            };
            skills = [
              "sks-k8s-audit"
              "sks-issue"
              "sks-fastlane"
            ];
            prompt = ''
              Daily Kubernetes warning-events triage for the nishir fleet.

              1. Read warning events with kubectl (context automata, credentials from the projected
                 service-account volume at /var/run/secrets/kubernetes.io/serviceaccount):
                 kubectl get events -A --field-selector type=Warning -o json. Parse with python3.
                 Group by involvedObject kind, namespace, name, and reason; record count,
                 lastTimestamp, and a one-line message.
              2. Cluster-level failures (node down, Longhorn recovery, storage): issue only.
              3. Before reporting: honcho_search "kubernetes events triage" and honcho_context -
                 reuse recurring context (objects that chronically emit warning events,
                 fastlane fixes that landed), then honcho_conclude write one line per durable
                 lesson.
            '';
          }
        ];
      };

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
                Implementation needs an explicit go-ahead.
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
