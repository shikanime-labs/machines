{
  pkgs,
  ...
}:

(pkgs.llama-cpp.override {
  vulkanSupport = true;
  rpcSupport = true;
}).overrideAttrs
  (_old: {
    version = "0.4.0-glm5next";
    src = pkgs.fetchFromGitHub {
      owner = "unslothai";
      repo = "llama.cpp";
      rev = "d94f44e79aa219d8057e8de21f95360a187ebf41";
      hash = "sha256-Z4OGKjsegqMu0Bj/EtPDkZuf4URCqvGvA4egEz52WmE=";
    };
  })
