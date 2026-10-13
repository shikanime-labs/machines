{
  buildPythonPackage,
  fetchFromGitHub,
  lib,
  setuptools,
}:

let
  version = lib.importJSON ./version.json;
in
buildPythonPackage {
  inherit (version) version;
  pname = "honcho-ai";
  pyproject = true;

  src = fetchFromGitHub version;

  sourceRoot = "source/sdks/python";

  build-system = [ setuptools ];

  dontCheckRuntimeDeps = true;
}
