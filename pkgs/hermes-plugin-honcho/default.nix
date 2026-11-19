{
  fetchFromGitHub,
  lib,
  stdenv,
}:

let
  version = lib.importJSON ./version.json;
in
stdenv.mkDerivation {
  inherit (version) version;
  pname = "hermes-plugin-honcho";

  src = fetchFromGitHub version;

  installPhase = ''
    runHook preInstall
    cp -r $src/hermes-plugin-honcho/. $out/
    runHook postInstall
  '';

  dontBuild = true;

  meta = {
    description = "Honcho AI-native memory plugin for Hermes Agent";
    license = lib.licenses.mit;
  };
}
