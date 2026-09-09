{ pkgs, ... }:

pkgs.symlinkJoin {
  name = "rtk-rewrite";
  paths = [
    "${
      pkgs.fetchFromGitHub {
        owner = "rtk-ai";
        repo = "rtk";
        rev = "v0.45.0";
        hash = "sha256-weAyHM0nWLrM8JRbbXIfjUsHtAep3DOFyTO+M3BZ/iU=";
      }
    }/hooks/hermes/rtk-rewrite"
  ];
}
