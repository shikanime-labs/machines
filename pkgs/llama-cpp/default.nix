# ROCm llama.cpp OCI image (gfx1151 Strix Halo) for the nix-containers
# Skaffold builder. The host kernel provides the amdgpu driver and exposes
# /dev/kfd + /dev/dri; the image carries only the ROCm userland.
{
  pkgs,
  lib,
}:
let
  llama-cpp = pkgs.llama-cpp.override {
    rocmSupport = true;
    rpcSupport = true;
  };
in
pkgs.dockerTools.buildLayeredImage {
  name = "llama-cpp-oci";
  tag = "latest";

  contents = [
    pkgs.dockerTools.caCertificates
    pkgs.dockerTools.usrBinEnv
    llama-cpp
  ];

  config = {
    Entrypoint = [
      "${llama-cpp}/bin/llama-server"
    ];
    Cmd = [
      "--host"
      "0.0.0.0"
      "--port"
      "8080"
    ];
    ExposedPorts = {
      "8080/tcp" = { };
    };
    Env = [ "HIP_VISIBLE_DEVICES=0" ];
    User = "65532:65532";
    WorkingDir = "/";
  };

  meta = with lib; {
    description = "llama.cpp ROCm (gfx1151) inference server container";
    platforms = [ "x86_64-linux" ];
  };
}
