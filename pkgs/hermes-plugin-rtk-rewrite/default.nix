{ pkgs, ... }:

pkgs.symlinkJoin {
  name = "rtk-rewrite";
  paths = [
    "${
      pkgs.fetchFromGitHub {
        owner = "rtk-ai";
        repo = "rtk";
        rev = "v0.44.0";
        hash = "sha256-Ev6w0Gi2y48DYi55GSciCoPgkUFaX44aH3UWGhs1OGk=";
      }
    }/hooks/hermes/rtk-rewrite"
  ];
}
