{
  perSystem =
    {
      inputs',
      pkgs,
      lib,
      system,
      ...
    }:
    lib.optionalAttrs (system == "x86_64-linux" || system == "aarch64-linux") {
      packages =
        let
          hermes-agent = pkgs.callPackage ../../pkgs/hermes-agent/default.nix {
            hermes-agent = inputs'.hermes-agent.packages.default;
          };
        in
        {
          huggingface-oci-image = pkgs.callPackage ../../pkgs/huggingface-oci-image/default.nix {
            inherit system;
          };
          llama-cpp-oci-image = pkgs.callPackage ../../pkgs/llama-cpp-oci-image/default.nix {
            inherit system;
          };
          inherit hermes-agent;
          hermes-agent-oci-image = pkgs.callPackage ../../pkgs/hermes-agent-oci-image/default.nix {
            inherit pkgs system hermes-agent;
          };
        };
    };
}
