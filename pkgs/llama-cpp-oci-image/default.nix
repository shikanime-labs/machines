{
  pkgs,
  lib,
  system,
  ...
}:

let
  rocmSupport = system == "x86_64-linux";
  vulkanSupport = system == "aarch64-linux";
  llama-cpp = pkgs.llama-cpp.override {
    inherit rocmSupport vulkanSupport;
    rpcSupport = true;
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
    Cmd = [
      "--host"
      "0.0.0.0"
      "--port"
      "9931"
    ];
    ExposedPorts = {
      "9931/tcp" = { };
    };
    Env = lib.optionals rocmSupport [ "HIP_VISIBLE_DEVICES=0" ];
    User = "65532:65532";
    WorkingDir = "/";
  };

  meta = with lib; {
    description =
      if rocmSupport then "llama.cpp ROCm server container" else "llama.cpp Vulkan server container";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
