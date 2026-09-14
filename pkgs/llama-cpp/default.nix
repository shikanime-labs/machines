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
      rev = "18443257a30c884d5332abb8e7dc43c7ffe42fda";
      hash = "sha256-4XdNU5CTc1hsOA+EZTUwUVqXKkjP6SFgUEaAZbtVVXM=";
    };
    patches = [
      # rpc: single-threaded accept loop starves every connection after the
      # first (router mode holds one long-lived RPC connection per model).
      ./rpc-thread-per-connection.patch
      # metrics: monitor scrape (/metrics) must not require an API key.
      ./metrics-public.patch
    ];
  })
