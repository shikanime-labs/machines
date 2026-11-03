{ hermes-agent, lib, libopus, ... }:

hermes-agent.overrideAttrs (_finalAttrs: previousAttrs: {
  # $out/share/hermes-agent/plugins is a read-only store symlink; replace the
  # link with the fleet copy from the input package (installed at
  # share/hermes-agent/plugins; -L dereferences the source symlink), then
  # point the discord adapter at an absolute libopus path (ldconfig is
  # absent on NixOS).
  postInstall = (previousAttrs.postInstall or "") + ''
    rm $out/share/hermes-agent/plugins
    cp --no-preserve=mode -rL ${hermes-agent}/share/hermes-agent/plugins $out/share/hermes-agent/plugins
    substituteInPlace $out/share/hermes-agent/plugins/platforms/discord/adapter.py \
      --replace-fail 'opus_path = ctypes.util.find_library("opus")' 'opus_path = "${lib.getLib libopus}/lib/libopus.so.0"'
  '';
})
