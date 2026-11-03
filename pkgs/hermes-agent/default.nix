{
  hermes-agent,
  lib,
  libopus,
  pkgs,
  ...
}:

let
  hermesPluginLcm = pkgs.callPackage ../hermes-plugin-lcm { };
  hermesPluginMemoryWiki = pkgs.callPackage ../hermes-plugin-memory-wiki { };
  hermesPluginPonytail = pkgs.callPackage ../hermes-plugin-ponytail { };
in
hermes-agent.overrideAttrs (_finalAttrs: previousAttrs: {
  # $out/share/hermes-agent/plugins is a read-only store symlink; replace the
  # link with the fleet copy from the input package (installed at
  # share/hermes-agent/plugins; -L dereferences the source symlink), add the
  # fleet's directory plugins (plugin discovery scans the bundled root), then
  # point the discord adapter at an absolute libopus path (ldconfig is
  # absent on NixOS).
  postInstall = (previousAttrs.postInstall or "") + ''
    rm $out/share/hermes-agent/plugins
    cp --no-preserve=mode -rL ${hermes-agent}/share/hermes-agent/plugins $out/share/hermes-agent/plugins
    cp --no-preserve=mode -r ${hermesPluginLcm} $out/share/hermes-agent/plugins/hermes-lcm
    cp --no-preserve=mode -r ${hermesPluginMemoryWiki} $out/share/hermes-agent/plugins/memory-wiki
    cp --no-preserve=mode -r ${hermesPluginPonytail} $out/share/hermes-agent/plugins/ponytail
    substituteInPlace $out/share/hermes-agent/plugins/platforms/discord/adapter.py \
      --replace-fail 'opus_path = ctypes.util.find_library("opus")' 'opus_path = "${lib.getLib libopus}/lib/libopus.so.0"'
  '';
})
