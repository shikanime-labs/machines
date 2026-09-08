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
  name = "llama-cpp";
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
    description = "llama.cpp ROCm inference server container";
    platforms = [ "x86_64-linux" ];
  };
}
