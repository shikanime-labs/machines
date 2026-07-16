{ pkgs, ... }:

{
  home.packages = [
    pkgs.git-credential-manager
  ];

  programs = {
    git = {
      enable = true;
      lfs.enable = true;
      settings.credential.helper = "manager";
    };

    jujutsu = {
      enable = true;
      settings = {
        aliases = {
          prune = [
            "abandon"
            "nulls()"
            "conflicts()"
          ];
          restack = [
            "rebase"
            "--onto"
            "trunk()"
            "--source"
            "roots(trunk()..) & mutable()"
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
          sync = [
            "git"
            "fetch"
            "--all-remotes"
          ];
        };
        git.private-commits = "description(substring:\"[private]\")";
        templates = {
          commit_trailers = ''
            format_signed_off_by_trailer(self)
            ++ if(!trailers.contains_key("Change-Id"), format_gerrit_change_id_trailer(self))
          '';
          git_push_bookmark = "\"shikanime/push-\" ++ change_id.short()";
        };
        revset-aliases = {
          "closest_merge(to)" = "heads(::to & merges())";
          "nulls()" = "empty() & mutable()";
        };
        ui.default-command = "log";
      };
    };
  };
}
