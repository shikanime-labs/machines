{
  pkgs,
  lib,
  ...
}:

let
  # ROCm is x86_64-only in nixpkgs; aarch64 stays on the Vulkan build.
  llama-cpp-rpc-base = pkgs.llama-cpp.override { rpcSupport = true; };
  llama-cpp-base =
    if pkgs.stdenv.hostPlatform.isx86_64 then pkgs.llama-cpp-rocm else pkgs.llama-cpp-vulkan;
  llama-cpp = llama-cpp-base.override { llama-cpp = llama-cpp-rpc-base; };
in
pkgs.dockerTools.buildLayeredImage {
  name = "llama-cpp";
  tag = "latest";

  contents = [
    pkgs.dockerTools.caCertificates
    pkgs.dockerTools.usrBinEnv
    llama-cpp
  ];

  fakeRootCommands = ''
    ${pkgs.dockerTools.shadowSetup}
    groupadd -g 65532 llama.cpp
    useradd -u 65532 -g 65532 -d /home/llama.cpp -M llama.cpp
    mkdir -p /home/llama.cpp
    chown llama.cpp:llama.cpp /home/llama.cpp
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
    Env = [ "HOME=/home/llama.cpp" ];
    ExposedPorts = {
      "9931/tcp" = { };
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
