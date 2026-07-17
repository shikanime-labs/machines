{ lib, pkgs, ... }:

with lib;

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
          fetch = [
            "git"
            "fetch"
            "--all-remotes"
          ];
          jjplus = [
            "util"
            "exec"
            "--"
            "${getExe pkgs.jjplus}"
          ];
          switch = [
            "util"
            "exec"
            "--"
            "${getExe pkgs.jjplus}"
            "switch"
          ];
          checkout = [
            "util"
            "exec"
            "--"
            "${getExe pkgs.jjplus}"
            "checkout"
          ];
          remove = [
            "util"
            "exec"
            "--"
            "${getExe pkgs.jjplus}"
            "remove"
          ];
          submit = [
            "util"
            "exec"
            "--"
            "${getExe pkgs.jjplus}"
            "submit"
          ];
          land = [
            "util"
            "exec"
            "--"
            "${getExe pkgs.jjplus}"
            "land"
          ];
          push = [
            "git"
            "push"
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
        ui = {
          default-command = "log";
          movement = {
            edit = true;
          };
        };
      };
    };
  };
}
