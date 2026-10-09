{
  buildPythonPackage,
  fetchFromGitHub,
  lib,
  setuptools,
}:

let
  src = fetchFromGitHub {
    owner = "plastic-labs";
    repo = "honcho";
    rev = "e2d2aba182862deeb846e5cd4a30a41bce0ed82a";
    hash = "sha256-EZWqItroZopzw1c0nSyujPWpsN5OAUG3TpQmTdYAAsY=";
  };
  pyproject = lib.importTOML "${src}/sdks/python/pyproject.toml";
  version = pyproject.project.version;
in
buildPythonPackage {
  inherit version;
  pname = "honcho-ai";
  pyproject = true;

  inherit src;

  sourceRoot = "source/sdks/python";

  build-system = [ setuptools ];

  dontCheckRuntimeDeps = true;
}
