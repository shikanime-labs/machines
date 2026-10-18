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
            cluster = {
              server = "https://kubernetes.default.svc.cluster.local:6443";
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
              expr = "0 8 * * *";
            };
            skills = [
              "sks-issue"
              "sks-fastlane"
            ];
            prompt = ''
              Daily alert triage for the nishir fleet.

              1. Read firing alerts (no auth, pod network):
                 curl -s http://vmalertmanager-vmks-victoria-metrics-k8s-stack.monitoring-system.svc:9093/api/v2/alerts
                 Parse with python3. Record alertname, labels, annotations, startsAt.
              2. Dedup: gh issue list -R shikanime-labs/manifests --state open; skip alerts already covered.
              3. New alert: gh issue create -R shikanime-labs/manifests --title "<alertname>: <summary>"
                 --body "labels, annotations, affected object, startsAt" --assignee yorha-operator if eligible.
              4. Fastlane path: if the fix is a small manifest patch (values bump, threshold, image pin),
                 clone https://github.com/shikanime-labs/manifests to /tmp, branch, commit with body +
                 Signed-off-by: Shikanime Deva <william.phetsinorath@shikanime.studio> + Related: <full
                 issue URL>, push, open PR with trailer Co-authored-by: Automata
                 <automata@shikanime.studio> and reviewer yorha-operator. Merge without review only when
                 ALL hold: trivial framing; <=5 files; <=100 changed lines; nothing matching
                 lock|secret|.enc.|auth|iam|cert|token; no schema/API change; gh pr checks green on the
                 exact head (gh pr merge --squash --admin --match-head-commit <head sha>), then comment
                 the receipt "Fastlane: merged without human review (CI green, eligibility passed).
                 Revert freely if not trivial." Pending or red checks: leave the PR open for the next
                 run; never wait. Any eligibility fail: leave the PR open. Max 3 fastlanes per run.
              5. Note alerts resolved since the last sweep; close nothing automatically.
              6. Before reporting: honcho_search "grafana alert triage" and
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
              expr = "15 8 * * *";
            };
            skills = [
              "sks-issue"
              "sks-fastlane"
            ];
            prompt = ''
              Daily Flux health triage for the nishir fleet.

              1. Read cluster state with kubectl (context automata, credentials from the projected
                 service-account volume at /var/run/secrets/kubernetes.io/serviceaccount): kubectl get kustomizations -A -o wide and
                 kubectl get helmreleases -A -o wide, plus -o json for conditions. List every object
                 whose Ready condition is False, with message and source revision. Report deliberately
                 suspended objects separately; never touch them.
              2. Dedup: gh issue list -R shikanime-labs/manifests --state open; tracked failures are
                 listed, never re-filed.
              3. New failure: gh issue create -R shikanime-labs/manifests with object, namespace,
                 Ready=False message, source revision, first-seen; assignee yorha-operator if eligible.
              4. Fastlane path: small manifest patch only (each overlay has its own Flux KS; rendered
                 manifests exclude certs), same gate and mechanics as the alert job: trivial framing;
                 <=5 files; <=100 lines; no lock|secret|.enc.|auth|iam|cert|token; no schema change;
                 checks green on the exact head; merge --squash --admin --match-head-commit; receipt
                 comment. Pending or red checks: leave the PR open; never wait. Max 3 per run.
              5. Cluster-level failures (node down, Longhorn recovery, storage): issue only.
              6. Before reporting: honcho_search "flux triage" and honcho_context - reuse
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
              expr = "30 8 * * *";
            };
            skills = [
              "sks-issue"
              "sks-fastlane"
            ];
            prompt = ''
              Daily CI failure sweep for shikanime-labs and shikanime-studio.

              1. gh repo list shikanime-labs --limit 100 --json nameWithOwner (same for
                 shikanime-studio), then gh run list -R <repo> --status failure --created
                 ">$(date -d "-24 hours" "+%Y-%m-%d")". Ignore renovate PRs, draft-PR CI skips, and
                 flakes that passed on rerun.
              2. Dedup: gh issue list -R <repo> --state open.
              3. New failure: one issue per repo+workflow in the repo where it failed - run URL,
                 failing job, first error lines (gh run view --log-failed), head sha. Assignee
                 yorha-operator if eligible.
              4. Fastlane path: trivial fixes only (CI yaml fix, action pin, typo) passing the same
                 gate: trivial framing; <=5 files; <=100 lines; no lock|secret|.enc.|auth|iam|cert|token;
                 checks green on the exact head; merge --squash --admin --match-head-commit; receipt
                 comment. Pending or red checks: leave the PR open; never wait. Max 3 per run.
              5. Console quirk: apps/server-only push branches run no CI - re-arm with
                 gh workflow run workflow-continuous-integration.yml --ref <branch>.
              6. Before reporting: honcho_search "CI failure sweep" and honcho_context -
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
              expr = "0 9 * * 1";
            };
            prompt = ''
              Weekly cluster-efficiency brainstorm with the A2A fleet.

              1. Discover peers with a2a_list. Every reachable peer participates; note unreachable
                 ones and continue.
              2. One a2a_call per peer: "From your vantage point, what is the single
                 highest-leverage efficiency improvement in the fleet right now (compute, storage,
                 cost, redundancy)?" Each answer must state: observation, evidence, proposed change,
                 expected saving.
              3. Aggregate: dedup overlapping proposals, rank by leverage / effort. Drop proposals
                 already filed or rejected (gh issue list -R shikanime-labs/manifests, open and
                 recently closed).
              4. File the top proposals (max 3) as issues in shikanime-labs/manifests, one per
                 proposal, crediting the contributing agents in the body. Proposals only - no PRs
                 from this job.
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
              expr = "45 8 * * *";
            };
            skills = [
              "sks-issue"
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
              3. Dedup: gh issue list -R shikanime-studio/websites --state open; tracked drift is
                 listed, never re-filed.
              4. New drift: gh issue create -R shikanime-studio/websites with page, claim, ground
                 truth, source links. Assignee yorha-operator if eligible.
              5. Fastlane path: small factual fix only (typo, stale name, corrected port), same gate
                 as the alert job: trivial framing; <=5 files; <=100 lines; no
                 lock|secret|.enc.|auth|iam|cert|token; no schema/API change; checks green on the
                 exact head (gh pr merge --squash --admin --match-head-commit <head sha>), then the
                 receipt comment. Pending or red checks: leave the PR open; never wait. Max 3 per
                 run. Websites commits carry Signed-off-by: Shikanime Deva
                 <william.phetsinorath@shikanime.studio> and trailer Co-authored-by: Automata
                 <automata@shikanime.studio>. Deploy stays manual - never wrangler deploy from this
                 job.
              6. Before reporting: honcho_search "documentation drift" and honcho_context -
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
              expr = "15 9 * * *";
            };
            skills = [
              "sks-issue"
              "sks-fastlane"
            ];
            prompt = ''
              Daily security audit for shikanime-labs and shikanime-studio.

              1. Enumerate org alerts: gh api /orgs/shikanime-labs/code-scanning/alerts --paginate
                 (same for secret-scanning and dependabot alerts, and all three again for
                 shikanime-studio); keep state=="open". Record alert type, repo, severity, CVE,
                 html_url, created_at.
              2. Dedup: gh issue list -R <repo> --state open; tracked alerts are listed, never
                 re-filed.
              3. New alert: gh issue create -R <affected repo> --title "<type>: <CVE or rule>" with
                 severity, affected path, first-seen, alert link. Assignee yorha-operator if
                 eligible. Rank critical and high first; secret-scanning alerts are always urgent.
              4. Fastlane path: small dependency bump or config fix only, same gate as the alert
                 job: trivial framing; <=5 files; <=100 lines; nothing matching
                 lock|secret|.enc.|auth|iam|cert|token; no schema/API change; checks green on the
                 exact head (gh pr merge --squash --admin --match-head-commit <head sha>), then the
                 receipt comment. Pending or red checks: leave the PR open; never wait. Max 3 per
                 run.
              5. Never close or dismiss alerts from this job; resolved alerts are noted only.
              6. Before reporting: honcho_search "security audit" and honcho_context -
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
              expr = "15 10 * * *";
            };
            skills = [
              "sks-issue"
              "sks-fastlane"
            ];
            prompt = ''
              Daily offensive security probe for shikanime-labs and shikanime-studio.

              1. Scope: the perimeter reachable from this host - public endpoints of the
                 fleet (Envoy Gateway routes and TLS hostnames from a depth-1 clone of
                 https://github.com/shikanime-labs/manifests), open TCP surfaces, exposed
                 dashboards, container registries, GitHub org attack surface (branch
                 protection, CI secrets exposure, webhook configs).
              2. Probe read-only: TLS validity and cipher posture (openssl s_client),
                 security headers on public routes (curl -sI), authentication bypass checks
                 on dashboards, anonymous API access, registry tag listability. Record
                 evidence (command, output excerpt) per finding. Never exploit past proof,
                 never modify or delete anything, never touch secrets.
              3. Cross-reference first: honcho_search "security audit" and honcho_search
                 "redteam probe" - findings already tracked or already proven by a previous
                 redteam run are listed, never re-filed.
              4. New finding: gh issue create -R shikanime-labs/manifests --title "redteam:
                 <finding>" with severity, evidence, affected route, suggested fix. Assignee
                 yorha-operator if eligible.
              5. Fastlane path: small hardening patch only (header addition, rate limit,
                 cipher policy), same gate as the alert job: trivial framing; <=5 files;
                 <=100 lines; no lock|secret|.enc.|auth|iam|cert|token; no schema/API
                 change; checks green on the exact head (gh pr merge --squash --admin
                 --match-head-commit <head sha>), then the receipt comment. Pending or red
                 checks: leave the PR open; never wait. Max 3 per run.
              6. Before reporting: honcho_reasoning "Which attack paths from previous probes
                 remain unpatched?" - re-verify the top open items instead of rediscovering
                 them, then honcho_conclude write one line per durable lesson.
            '';
          }
          {
            id = "f077dc14361e";
            name = "daily-renovate-sweep";
            enabled = true;
            deliver = "local";
            schedule = {
              kind = "cron";
              expr = "30 10 * * *";
            };
            skills = [ "sks-triage" ];
            prompt = ''
              Daily sweep of open renovate PRs across shikanime-labs and shikanime-studio.

              1. Enumerate: gh repo list shikanime-labs --limit 100 --json nameWithOwner (same
                 for shikanime-studio), then gh pr list -R <repo> --author app/renovate
                 --state open --json number,title,headRefName,updatedAt,statusCheckRollup.
              2. Triage per PR: green checks on the exact head -> eligible; red checks ->
                 read gh pr checks and the failing job's first error lines (gh run view
                 <run> --log-failed); stalled (no check runs, CI not triggered) ->
                 note the re-arm path per repo quirk. Drop PRs whose branch is behind
                 main with a merge conflict - renovate rebases those itself.
              3. Never merge, close, or approve anything from this job - landing renovate
                 PRs needs an explicit human go-ahead. Report only: one line per PR with
                 repo, number, update, check state, and the blocking reason when red.
              4. A PR red for 3+ consecutive days with the same error: one summary issue
                 in its repo (dedup: gh issue list --state open) with the error pattern;
                 assignee yorha-operator if eligible.
              5. Before reporting: honcho_search "renovate sweep" and honcho_context -
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
              expr = "30 9 * * *";
            };
            skills = [ "sks-triage" ];
            prompt = ''
              Daily GitHub triage for shikanime-labs and shikanime-studio.

              1. Enumerate: gh repo list shikanime-labs --limit 100 --json nameWithOwner (same for
                 shikanime-studio), then gh issue list -R <repo> --state open --json (same for PRs).
                 Collect unlabeled or unassigned issues older than 48h, PRs with requested changes
                 or red checks, and issues awaiting a first reply for 7+ days.
              2. Dedup: an item already labeled, assigned, or covered by a previous run is listed,
                 not re-triaged.
              3. Triage: apply missing type and area labels, assign yorha-operator where eligible,
                 comment a first reply on unanswered issues. One summary issue per systemic finding
                 (repeat failure, cross-repo pattern) in the repo where it belongs.
              4. Triage only - no PRs from this job; label, comment, and assign via gh only. Close
                 nothing automatically; note items resolved since the last sweep.
              5. Before reporting: honcho_search "GitHub triage" and honcho_context -
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
              expr = "45 9 * * *";
            };
            skills = [ ];
            prompt = ''
              Daily GitHub cleanup for shikanime-labs and shikanime-studio.

              1. Enumerate: gh repo list shikanime-labs --limit 100 --json nameWithOwner (same for
                 shikanime-studio), then for each repo list fully-merged remote branches with
                 gh api repos/<repo>/branches --paginate. A branch is stale when its head is an
                 ancestor of the default branch (gh api repos/<repo>/compare/<default>...<branch>
                 status=="identical" or behind), or its PR is closed/merged. Never touch the
                 default branch, protected branches, release/* tags, or ghstack role branches
                 (<prefix>/base|head|orig) of OPEN ghstack stacks - only fully-landed ones.
              2. Dedup: branches deleted in previous runs are gone from the list by nature; list
                 (never re-delete) anything a previous run flagged as blocked (open PR, recent
                 push < 7 days).
              3. Delete stale branches older than 7 days with gh api -X DELETE
                 repos/<repo>/git/refs/heads/<branch> or git push origin --delete after a depth-1
                 clone. Branches of closed-but-unmerged PRs are only deleted after 30 days idle.
              4. Before reporting: honcho_search "stale branch cleanup" and honcho_context -
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
              expr = "0 10 * * *";
            };
            skills = [ "sks-triage" ];
            prompt = ''
              Daily sweep of unread GitHub notifications for shikanime-labs and
              shikanime-studio.

              1. List unread threads: gh api /notifications --paginate -H 'Accept: application/vnd.github+json'.
                 Record reason, subject title and type, repository, updated_at, subject url.
              2. Open a thread only when the reason demands detail (review_requested, ci_activity,
                 assign, author): gh api <subject url> for state and latest context. Skip that for
                 mention/subscription noise.
              3. Dedup: a thread already summarized by a previous run and unchanged since is skipped
                 silently. The repo has no continuity — check the thread's updated_at against the
                 last sweep's coverage in the cron run output dir if needed.
              4. Act per item: clearly answerable question → reply as a comment via gh as
                 yorha-operator (never approve or merge anything); needs a human decision → one
                 bullet in the report; pure noise (renovate, bot echoes, auto-closes) → nothing.
              5. Mark processed threads read: PATCH /notifications/threads/<id>. Never leave the
                 same thread in two consecutive reports.
              6. Before reporting: honcho_search "notification sweep" and honcho_context -
                 reuse recurring context (threads a previous run answered, noise
                 patterns to skip), then honcho_conclude write one line per durable
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
                validate how to solve it with all assignees, in the issue,
                before any development. Development is a deliberate act — do
                not start implementation without an explicit go-ahead.
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
            github-moderation = {
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
                  field = "sender.login";
                  not_equals = "yorha-operator";
                }
                {
                  not = {
                    field = "comment.body";
                    contains = "@yorha-operator";
                  };
                }
              ];
              prompt = ''
                Moderate the comment at {comment.html_url}.
              '';
              skills = [ "sks-moderate" ];
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
                  ];
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
