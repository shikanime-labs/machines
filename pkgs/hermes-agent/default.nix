{
  hermes-agent,
  lib,
  pkgs,
  ...
}:

# Everything the fleet decides about hermes-agent lives here: the dependency
# groups, the Python plugin packages, the directory plugins, and the libopus
# patch. Hosts and the brain image consume the same derivation.
let
  plugins = import ./plugins.nix { inherit pkgs; };

  python = hermes-agent.python.pkgs;

  # `default` is `minimal.override { extraDependencyGroups = …; }` and the venv
  # takes the list verbatim (`[ "all" ] ++ extraDependencyGroups`), so this is
  # the complete set the fleet gets — not an addition to the shipped groups.
  extraDependencyGroups = [
    "anthropic"
    "computer-use"
    "matrix"
    "messaging"
    "piper"
    "voice"
  ];

  extraPythonPackages = [
    (python.callPackage ../honcho-ai { })
    (python.callPackage ../hermes-plugin-honcho { })
  ];
in
{
  inherit plugins extraDependencyGroups;

  # The one thing upstream cannot know is where libopus lives: NixOS has no
  # ldconfig, so `ctypes.util.find_library("opus")` returns null and the
  # discord adapter never loads the codec. Seed its first candidate with the
  # absolute store path; the adapter's own fallbacks stay intact.
  package =
    (hermes-agent.override { inherit extraDependencyGroups extraPythonPackages; }).overrideAttrs
      (
        _finalAttrs: previousAttrs: {
          postInstall = (previousAttrs.postInstall or "") + ''
            substituteInPlace $out/share/hermes-agent/plugins/platforms/discord/adapter.py \
              --replace-fail 'opus_path = ctypes.util.find_library("opus")' 'opus_path = "${lib.getLib pkgs.libopus}/lib/libopus.so.0"'
          '';
        }
      );
}
