{ inputs, ... }:

{
  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    {
      packages = {
        hermes-plugin-lcm = import ../../pkgs/hermes-plugin-lcm { inherit pkgs; };
        hermes-plugin-rtk-rewrite = import ../../pkgs/hermes-plugin-rtk-rewrite { inherit pkgs; };
      };
    }
    // lib.optionalAttrs (system == "x86_64-linux" || system == "aarch64-linux") {
      packages = {
        huggingface-oci-image = pkgs.callPackage ../../pkgs/huggingface-oci-image/default.nix {
          inherit system;
        };
        llama-cpp-oci-image = pkgs.callPackage ../../pkgs/llama-cpp-oci-image/default.nix {
          inherit system;
        };
        hermes-agent-oci-image = pkgs.callPackage ../../pkgs/hermes-agent-oci-image/default.nix {
          hermes-agent = inputs.hermes-agent.packages.${system}.default;
        };
      };
    };
}
