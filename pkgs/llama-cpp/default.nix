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
    rev = "4364bf7232e65c34eca8d9500c5464389662de6b";
    hash = "sha256-0h33h04p92wfb01p4yrgw9vvzim8rbfz3w6v9dhg8w5wvm4af3kx=";
  };
  patches = [
    # rpc: single-threaded accept loop starves every connection after the
    # first (router mode holds one long-lived RPC connection per model).
    ./rpc-thread-per-connection.patch
    # metrics: monitor scrape (/metrics) must not require an API key.
    ./metrics-public.patch
  ];
})
