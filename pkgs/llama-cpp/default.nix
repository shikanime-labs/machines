{
  pkgs,
  ...
}:

(pkgs.llama-cpp.override {
  vulkanSupport = true;
  rpcSupport = true;
}).overrideAttrs
  (_old: {
    version = "0.4.0";
    src = pkgs.fetchFromGitHub {
      owner = "ggml-org";
      repo = "llama.cpp";
      rev = "8ea290247c87ced2ab245b056ffe96dbcf90d36c";
      hash = "sha256-xfYNmpyXP/Uhg2zetwcBSMwvM5dK807K4dpdzonBlKA=";
    };
  })
