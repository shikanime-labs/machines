{
  pkgs,
  lib,
  system,
  ...
}:

let
  rocmSupport = system == "x86_64-linux";
  vulkanSupport = system == "aarch64-linux";
  glm5nextSrc = pkgs.fetchFromGitHub {
    owner = "unslothai";
    repo = "llama.cpp";
    rev = "b9b8207fcfc2962093b9466df7af4ff29c2a81ef";
    hash = "sha256-V8a8OzIKeFBBJGAIiyIuRdT215mLTmGBLHWzfU8If4o=";
  };
  llama-cpp =
    (pkgs.llama-cpp.override {
      inherit rocmSupport vulkanSupport;
      rpcSupport = true;
    }).overrideAttrs
      (_old: {
        version = "0.4.0-glm5next";
        src = glm5nextSrc;
      });
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
    Entrypoint = [ "${llama-cpp}/bin/ggml-rpc-server" ];
    Cmd = [
      "--host"
      "0.0.0.0"
      "--port"
      "50052"
    ];
    ExposedPorts = {
      "50052/tcp" = { };
    };
    Env = lib.optionals rocmSupport [ "HIP_VISIBLE_DEVICES=0" ];
    User = "65532:65532";
    WorkingDir = "/";
  };

  meta = with lib; {
    description =
      if rocmSupport then
        "llama.cpp ROCm RPC server container"
      else
        "llama.cpp Vulkan RPC server container";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
