{
  pkgs,
  lib,
  system,
  ...
}:

let
  llama-cpp = pkgs.callPackage ../llama-cpp/default.nix {
    inherit system;
    rocmSupport = false;
    vulkanSupport = false;
  };
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
    ExposedPorts = {
      "8080/tcp" = { };
    };
    User = "65532:65532";
    WorkingDir = "/";
  };

  meta = with lib; {
    description = "llama.cpp server container";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
