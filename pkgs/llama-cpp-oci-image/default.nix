{
  pkgs,
  lib,
  ...
}:

let
  llama-cpp = pkgs.callPackage ../llama-cpp/default.nix { };
in
pkgs.dockerTools.buildLayeredImage {
  name = "llama-cpp-oci-image";
  tag = "latest";

  contents = [
    pkgs.dockerTools.caCertificates
    pkgs.dockerTools.usrBinEnv
    llama-cpp
  ]
  ++ lib.optional pkgs.stdenv.hostPlatform.isx86_64 pkgs.mesa;

  extraCommands = lib.optionalString pkgs.stdenv.hostPlatform.isx86_64 ''
    mkdir -p etc/vulkan/icd.d
    ln -sf ${pkgs.mesa}/share/vulkan/icd.d/*.json etc/vulkan/icd.d/
  '';
  fakeRootCommands = ''
    ${pkgs.dockerTools.shadowSetup}
    groupadd -g 65532 llama
    useradd -u 65532 -g 65532 -d /home/llama -M llama
    mkdir -p /home/llama
    chown llama:llama /home/llama
  '';
  enableFakechroot = true;

  config = {
    Entrypoint = [ "${llama-cpp}/bin/llama-server" ];
    Cmd = [
      "--host"
      "0.0.0.0"
      "--port"
      "9931"
    ];
    Env =
      lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
        "VK_DRIVER_FILES=${pkgs.mesa}/share/vulkan/icd.d/radeon_icd.${pkgs.stdenv.hostPlatform.parsed.cpu.name}.json"
      ]
      ++ [
        "HOME=/home/llama"
        "MESA_SHADER_CACHE_DIR=/home/llama/.cache"
      ];
    ExposedPorts = {
      "9931/tcp" = { };
    };
    User = "65532:65532";
    WorkingDir = "/";
  };

  meta = with lib; {
    description = "llama.cpp Vulkan server container";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
