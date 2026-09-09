{
  pkgs,
  system,
  ...
}:

let
  rocmSupport = system == "x86_64-linux";
  vulkanSupport = system == "aarch64-linux";
in
(pkgs.llama-cpp.override {
  inherit rocmSupport vulkanSupport;
  rpcSupport = true;
}).overrideAttrs
  (_old: {
    version = "0.4.0-glm5next";
    src = pkgs.fetchFromGitHub {
      owner = "unslothai";
      repo = "llama.cpp";
      rev = "b9b8207fcfc2962093b9466df7af4ff29c2a81ef";
      hash = "sha256-V8a8OzIKeFBBJGAIiyIuRdT215mLTmGBLHWzfU8If4o=";
    };
  })
