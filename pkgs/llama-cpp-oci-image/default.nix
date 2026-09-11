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
  ];

  config = {
    Entrypoint = [ "${llama-cpp}/bin/llama-server" ];
    Cmd = [
      "--host"
      "0.0.0.0"
      "--port"
      "9931"
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
