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
    // lib.optionalAttrs (system == "x86_64-linux") {
      # ROCm userland is x86_64-linux only; expose the image only there so
      # `flake.packages.x86_64-linux.llama-cpp-oci` is the single entry point.
      packages.llama-cpp-oci = import ../../pkgs/llama-cpp { inherit pkgs lib; };
    };
}
