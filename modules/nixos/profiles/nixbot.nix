{ config, lib, ... }:

# Nixbot control node: a zero-config, pull-based, self-hosted Nix CI that
# builds `.#checks` on PR open and default-branch push. Runs on ONE control
# host; builds offload to the existing nix remote builders declared by
# `distributed.nix`. Requires the `nixbot` flake input
# (github:Mic92/nixbot) wired into the host's module list.
{
  imports = [
    ./machine.nix
    ./distributed.nix
  ];

  services.nixbot = {
    enable = true;

    # Web frontend + GitHub App webhook endpoint.
    domain = "nixbot.taila659a.ts.net";

    # Control-plane user; the CI owner. Provider-qualified "github:<login>".
    admins = [ "github:shikanimedeva" ];

    # GitHub App auth (see docs/GITHUB.md): automatic webhook setup + check-run
    # reporting with a working Re-run button. Files land via sops.
    github = {
      enable = true;
      appId = 0; # FIXME: GitHub App ID
      appSecretKeyFile = config.sops.secrets.nixbot-app-secret.path;
      webhookSecretFile = config.sops.secrets.nixbot-webhook-secret.path;
      oauthId = "aaaaaaaaaaaaaaaaaaaa"; # FIXME: OAuth client id
      oauthSecretFile = config.sops.secrets.nixbot-oauth-secret.path;
      # One-shot import on first boot: repositories with this topic are enabled.
      topic = "build-with-buildbot";
      # Only the org we actually build.
      userAllowlist = [ "shikanime-labs" ];
    };

    # Systems built locally; everything else arrives via nix remote builders
    # from `distributed.nix`.
    buildSystems = [ "x86_64-linux" ];

    # Bound eval so a busy org cannot starve the control node.
    evalWorkerCount = 2;
    evalMaxMemorySize = 4096;

    nginx.enableACME = true;
  };

  sops.secrets = {
    nixbot-app-secret.restartUnits = [ "nixbot.service" ];
    nixbot-webhook-secret.restartUnits = [ "nixbot.service" ];
    nixbot-oauth-secret.restartUnits = [ "nixbot.service" ];
  };

  # Nixbot drives the local nix daemon; the remote-build trust model lives in
  # `distributed.nix` (imported above), which trusts the `builder` user.
  nix.settings.max-jobs = lib.mkDefault 2;

  # Let's Encrypt terms; nixbot provisions a cert for `domain`.
  security.acme.acceptTerms = true;
}
