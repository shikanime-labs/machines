{
  pkgs,
  ...
}:

(pkgs.llama-cpp-vulkan.override {
  llama-cpp = pkgs.llama-cpp.override { rpcSupport = true; };
}).overrideAttrs
  (_old: {
    version = "0.4.0";
    src = pkgs.fetchFromGitHub {
      owner = "ggml-org";
      repo = "llama.cpp";
      rev = "96ffdc41ceb055e1c2d3d96667ae6d9f0ccb710b";
      hash = "sha256-uFsYilaXd0Aay7ywDvFgVPw25xpPtcE4maXy4cBzpk8=";
    };
    patches = [
      # rpc: single-threaded accept loop starves every connection after the
      # first (router mode holds one long-lived RPC connection per model).
      ./rpc-thread-per-connection.patch
      # metrics: monitor scrape (/metrics) must not require an API key.
      ./metrics-public.patch
    ];
  })
