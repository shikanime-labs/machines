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
      };
    }
    // lib.optionalAttrs (system == "x86_64-linux" || system == "aarch64-linux") {
      packages = {
        dsh-oci-image = pkgs.callPackage ../../pkgs/dsh-oci-image/default.nix {
          dsh = inputs.llm-agents.packages.${system}.dsh;
        };
        huggingface-oci-image = pkgs.callPackage ../../pkgs/huggingface-oci-image/default.nix {
          inherit system;
        };
        llama-cpp-oci-image = pkgs.callPackage ../../pkgs/llama-cpp-oci-image/default.nix {
          inherit system;
        };
      };
    };
}
