{ ... }:
{
  imports = [
    ./profiles/inference.nix
  ];
  networking.hostName = "sashina";
  services.inference = {
    enable = true;
    role = "rpc";
    # Shard backend: exposes its GPU to kushira's llama-server over RPC.
    model = "/var/lib/llama-cpp/DeepSeek-V4-Flash-0731-UD-IQ4_XS-00001-of-00008.gguf";
  };
}
