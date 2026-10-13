{
  buildPythonPackage,
  fetchFromGitHub,
  lib,
  python,
}:

let
  version = lib.importJSON ./version.json;
in
buildPythonPackage {
  inherit (version) version;
  pname = "hermes-plugin-honcho";
  format = "other";

  src = fetchFromGitHub version;

  installPhase = ''
    runHook preInstall
    sp=$out/${python.sitePackages}
    mkdir -p $sp/hermes_plugin_honcho $sp/hermes_plugin_honcho-${version.version}.dist-info
    cp -r $src/hermes-plugin-honcho/. $sp/hermes_plugin_honcho/
    cat > $sp/hermes_plugin_honcho-${version.version}.dist-info/METADATA <<'EOF'
    Metadata-Version: 2.1
    Name: hermes-plugin-honcho
    EOF
    cat > $sp/hermes_plugin_honcho-${version.version}.dist-info/entry_points.txt <<'EOF'
    [hermes_agent.memory_providers]
    honcho = hermes_plugin_honcho:register
    EOF
    touch $sp/hermes_plugin_honcho-${version.version}.dist-info/RECORD
    runHook postInstall
  '';

  dontBuild = true;
}
