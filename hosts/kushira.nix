{ ... }:
{
  imports = [
    ./profiles/inference.nix
  ];
  networking.hostName = "kushira";
  services.inference = {
    enable = true;
    role = "server";
    # Primary: holds half the layers locally, offloads the rest to sashina.
    model = "/var/lib/llama-cpp/DeepSeek-V4-Flash-0731-UD-IQ4_XS-00001-of-00008.gguf";
    peer = "sashina.taila659a.ts.net:50052";
  };
}
