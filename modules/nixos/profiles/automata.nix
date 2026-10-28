{ config, pkgs, ... }:

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

      hermesHomeFiles."cron/jobs.json" = builtins.toJSON {
        jobs = [
          {
            id = "adfc09a25ae9";
            name = "daily-docs-sync";
            enabled = true;
            deliver = "local";
            schedule = {
              kind = "cron";
              expr = "45 0 * * *";
            };
            skills = [
              "sks-wiki"
              "sks-issue"
              "sks-commit"
              "sks-pr"
              "sks-fastlane"
            ];
            prompt = ''
              Daily docs sync for the fleet: mirror recent org changes into the
              per-repo GitHub wikis, then keep docs.shikanime.studio factually true.

              1. Enumerate recently changed repos, one query per org (shikanime-labs,
                 shikanime-studio, cloud-pi-native):
                 gh api -H 'Accept: application/vnd.github.cloak-preview' "search/commits?q=org%3A<org>+committer-date%3A>$(date -u -d '-30 days' +%F)&per_page=100&sort=committer-date&order=desc" --jq '.items[] | [.repository.full_name, .commit.committer.date, (.commit.message | split("\n")[0])] | @tsv'
                 The explicit sort matters: without sort=committer-date&order=desc the search returns
                 best-match results and the org cap fills with the oldest commits of the window.
                 Group by repo and drop repos whose only changes are dependency noise (renovate,
                 bump, pin, chore(deps) subjects). Expect roughly 20 repos: do NOT cap this list
                 before the wiki probe in step 2 - the repos carrying a wiki are the ones that
                 matter and they are not the most recently changed ones.
                 Never add -repo: excludes: org plus negated repo qualifiers return zero results
                 on GitHub commit search.
              2. Probe every candidate wiki, one line each:
                 git ls-remote "https://github.com/<owner>/<repo>.wiki.git" HEAD
                 Empty output means the wiki has no pages: page creation is a manual GitHub UI step,
                 so never attempt it here - collect those repos for one report line.
                 Otherwise clone it shallow - git clone --depth 1 -q
                 "https://github.com/<owner>/<repo>.wiki.git" /tmp/<repo>.wiki - and compare
                 git -C /tmp/<repo>.wiki log -1 --format=%cI with the newest change timestamp of
                 that repo from step 1. A wiki equal to or newer than its repo is already in sync:
                 skip it silently. Keep the rest as lagging.
              3. Sync the lagging wikis, stalest first (oldest wiki commit first), AT MOST 2 PER RUN;
                 list every other lagging wiki as a Deferred bullet. The order is self-correcting: a
                 wiki you just synced becomes the newest and drops to the back, so the backlog drains
                 instead of one busy repo winning every run, and a wiki that is already current is
                 never re-synced.
                 Page doctrine: a page documents THIS repo own internals - architecture, mechanics,
                 runbooks, procedure detail - never another repo automation, jobs or machinery.
                 Update the page that already covers the changed area; add a page only when a whole
                 new subsystem appeared, and then register it in BOTH Home.md and _Sidebar.md in the
                 same commit - an unlisted page is unreachable. Head each new page with
                 `<!-- owner: Automata | zone: technical | purpose: <one line> -->` and keep the
                 voice of the pages already there.
                 Ground every claim in the changed code (gh api repos/<owner>/<repo>/commits/<sha>,
                 or a depth 1 clone under /tmp), never in a commit subject, never in another wiki
                 page.
              4. Land each wiki update as ONE commit on master - no PR, no review, no sign-off, a
                 wiki bypasses branch protection by design: imperative one line title, blank line,
                 then Co-authored-by: Automata <automata@shikanime.studio>.
                 Push with the GitHub token, never through origin (the hermes user has no SSH key):
                 git -C /tmp/<repo>.wiki push -q "https://x-access-token:$GITHUB_TOKEN@github.com/<owner>/<repo>.wiki.git" HEAD:master
                 Verify with git ls-remote
                 "https://x-access-token:$GITHUB_TOKEN@github.com/<owner>/<repo>.wiki.git" HEAD and
                 require it to equal git -C /tmp/<repo>.wiki rev-parse HEAD. A push success line is
                 not proof.
              5. docs.shikanime.studio drift check, unchanged scope: clone
                 https://github.com/shikanime-studio/websites (depth 1) to /tmp; the site is
                 apps/docs, pages under apps/docs/docs/<section>/, sidebars.ts, product table.
                 Verify factual claims against ground truth - deployed manifests (clone
                 https://github.com/shikanime-labs/manifests depth 1), live cluster state (kubectl,
                 context automata), repo git logs - never from memory. Stale references are the norm.
                 Drift between a documented service (name, hostname, port, image) and its manifest is
                 a defect. File new drift in shikanime-studio/websites: page, claim, ground truth,
                 source links. Assignee yorha-operator if eligible. Small factual fixes only (typo,
                 stale name, corrected port): fastlane. Deploy stays manual - never wrangler deploy
                 from this job. If step 3 already spent the run, report this step as Deferred
                 instead of starting it.

              Report: one bullet per wiki page updated (repo, page, change mirrored), the Deferred
              list, one line naming the changed repos whose wiki has no pages yet, then the drift
              findings with the issues and PRs opened.
            '';
          }
          {
            id = "3453978b1312";
            name = "weekly-fleet-efficiency-audit";
            enabled = true;
            deliver = "local";
            schedule = {
              kind = "cron";
              expr = "0 1 * * 1";
            };
            skills = [ "sks-issue" ];
            prompt = ''
              Weekly fleet-efficiency brainstorm with the A2A fleet.

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
              5. Audit family policy: at most 3 filed issues per run; never close,
                 dismiss or edit what the brainstorm touches; proposals only, no PRs.
              6. Before reporting: honcho_search "fleet efficiency" and honcho_reasoning
                 "Which efficiency lessons from previous audits still apply?" - drop proposals
                 already tried and rejected, then honcho_conclude write one line per durable
                 lesson.
            '';
          }
          {
            id = "a13c7b90e4f2";
            name = "daily-fleet-health-audit";
            enabled = true;
            deliver = "local";
            schedule = {
              kind = "cron";
              expr = "15 1 * * *";
            };
            skills = [
              "sks-audit"
              "sks-issue"
              "sks-commit"
              "sks-pr"
              "sks-fastlane"
            ];
            prompt = ''
              Daily fleet health audit over the entire fleet and its orgs
              (shikanime-labs, shikanime-studio and cloud-pi-native), across every
              sks-audit surface: GitHub security alerts, perimeter redteam, CI
              failures, alertmanager alerts, Flux readiness, Kubernetes warning
              events.

              1. Cover every surface each run; the skill owns procedure, filing,
                 adversarial discovery and the memory loop.
              2. File issues across all three orgs on equal footing: no author
                 filtering, no repo exclusions.
              3. After the surfaces: hunt for audit gaps the surfaces do not cover
                 yet - an org repo, fleet endpoint, alert class or failure mode with
                 no surface - and file one issue per gap in shikanime-labs/manifests
                 proposing the new surface (what to read, with which command).
              4. Audit family policy: at most 3 filed issues per run; never close,
                 dismiss, silence or edit anything audited; fastlane only where the
                 owning skill's surface allows it.
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
            '';
          }
          {
            id = "3c7ce2a4c3e1";
            name = "15m-github-notification-sweep";
            enabled = true;
            deliver = "local";
            schedule = {
              kind = "cron";
              expr = "2,17,32,47 * * * *";
            };
            skills = [
              "sks-github-notif-sweep"
              "sks-triage"
            ];
            prompt = ''
              Frequent sweep of unread GitHub notifications for shikanime-labs and
              shikanime-studio.
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
              "sks-maintenance"
              "sks-issue"
              "sks-land"
            ];
            prompt = ''
              Daily landing pass over open renovate PRs across shikanime-labs,
              shikanime-studio and cloud-pi-native.
            '';
          }
          {
            id = "98bded605070";
            name = "monthly-sdlc-efficiency-audit";
            enabled = true;
            deliver = "local";
            schedule = {
              kind = "cron";
              expr = "0 3 1 * *";
            };
            skills = [
              "sks-audit"
              "sks-issue"
            ];
            prompt = ''
              Monthly SDLC efficiency audit for shikanime-labs and shikanime-studio,
              over the sks-audit SDLC efficiency surface.

              1. Measure every surface metric each run: census, untriaged scan,
                 review and merge latency with bot rows split out, merged-PR
                 residue, landing-gate stalls, stale branches; the skill owns
                 procedure, filing, dedup and the memory loop.
              2. Dedup findings against open issues in
                 shikanime-labs/manifests: gh issue list -R shikanime-labs/manifests
                 --state open. Already-tracked findings are listed, never re-filed.
              3. Audit family policy: at most 3 filed issues per run in
                 shikanime-labs/manifests, each acceptance ledger carrying the
                 measured baseline; never close, dismiss, silence or edit anything
                 audited; the SDLC surface allows no fastlane PR; the run is
                 interrupted at about 3 minutes.
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
