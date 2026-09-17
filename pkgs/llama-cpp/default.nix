{
  pkgs,
  lib,
  ...
}:

let
  llama-cpp-base = pkgs.llama-cpp.override { rpcSupport = true; };
  # ROCm (x86_64-only in nixpkgs) executes qwen4exp/deepseek-v4 graphs RADV
  # loses on first queue submit; aarch64 stays on the Vulkan build.
  llama-cpp-gpu =
    if pkgs.stdenv.hostPlatform.isx86_64 then
      (pkgs.llama-cpp-rocm.override { llama-cpp = llama-cpp-base; })
    else
      pkgs.llama-cpp-vulkan.override { llama-cpp = llama-cpp-base; };
in
llama-cpp-gpu.overrideAttrs (_old: {
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
