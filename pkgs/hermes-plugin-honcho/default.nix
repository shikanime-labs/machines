{
  buildPythonPackage,
  fetchFromGitHub,
  lib,
  python,
}:

let
  src = fetchFromGitHub {
    owner = "plastic-labs";
    repo = "honcho";
    rev = "e2d2aba182862deeb846e5cd4a30a41bce0ed82a";
    hash = "sha256-EZWqItroZopzw1c0nSyujPWpsN5OAUG3TpQmTdYAAsY=";
  };
  pyproject = lib.importTOML "${src}/hermes-plugin-honcho/pyproject.toml";
  version = pyproject.project.version;
in
buildPythonPackage {
  inherit version;
  pname = "hermes-plugin-honcho";
  format = "other";

  inherit src;

  installPhase = ''
    runHook preInstall
    sp=$out/${python.sitePackages}
    mkdir -p $sp/hermes_plugin_honcho $sp/hermes_plugin_honcho-${version}.dist-info
    cp -r $src/hermes-plugin-honcho/. $sp/hermes_plugin_honcho/
    cat > $sp/hermes_plugin_honcho-${version}.dist-info/METADATA <<'EOF'
    Metadata-Version: 2.1
    Name: hermes-plugin-honcho
    EOF
    cat > $sp/hermes_plugin_honcho-${version}.dist-info/entry_points.txt <<'EOF'
    [hermes_agent.memory_providers]
    honcho = hermes_plugin_honcho:register
    EOF
    touch $sp/hermes_plugin_honcho-${version}.dist-info/RECORD
    runHook postInstall
  '';

  dontBuild = true;
}
