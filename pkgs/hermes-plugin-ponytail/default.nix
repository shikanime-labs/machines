{
  lib,
  pkgs,
  ...
}:

let
  version = lib.importJSON ./version.json;
in
pkgs.fetchFromGitHub version
