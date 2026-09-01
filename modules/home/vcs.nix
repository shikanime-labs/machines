{ config, pkgs, ... }:

{
  imports = [
    ./gh.nix
  ];

  home.packages = [
    pkgs.git-credential-manager
  ];

  programs = {
    delta.enable = true;

    git = {
      enable = true;
      lfs.enable = true;
      ignores = [
        ".hermes/"
        ".worktrees/"
      ];
      settings = {
        core.excludesFile = "${config.home.homeDirectory}/.config/git/ignore";
        credential.helper = "manager";
      };
    };

    jujutsu = {
      enable = true;
      settings = {
        aliases = {
          prune = [
            "abandon"
            "empty() & mutable()"
            "conflicts()"
          ];
          restack = [
            "rebase"
            "--onto"
            "trunk()"
            "--source"
            "branch_heads()"
            "--simplify-parents"
          ];
          stack = [
            "rebase"
            "--after"
            "trunk()"
            "--before"
            "closest_merge(@)"
          ];
          stage = [
            "stack"
            "-r"
            "closest_merge(@)+:: ~ empty()"
          ];
          fetch = [
            "git"
            "fetch"
            "--all-remotes"
          ];
          switch = [
            "workspace"
            "add"
          ];
          push = [
            "git"
            "push"
          ];
        };
        git.private-commits = "description(substring:\"[private]\")";
        templates.commit_trailers = ''
          format_signed_off_by_trailer(self)
          ++ if(!trailers.contains_key("Change-Id"), format_gerrit_change_id_trailer(self))
        '';
        remotes.upstream.auto-track-bookmarks = "main";
        revset-aliases = {
          # Merge commits closest to `to` that are ancestors of @.
          "closest_merge(to)" = "heads(::to & merges())";
          # Mutable commits stacked within 2 hops of the mutable trunk frontier.
          "stacked()" = "ancestors(reachable(trunk(), mutable()), 2) & mutable()";
          # Mutable branch heads off trunk, excluding tagged releases.
          "branch_heads()" = "roots(trunk()..) & mutable() & ~tags()";
        };
        ui = {
          default-command = "log";
          movement.edit = true;
        };
      };
    };
  };
}
