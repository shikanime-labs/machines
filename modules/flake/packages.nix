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
      packages.llama-cpp = pkgs.callPackage ../../pkgs/llama-cpp-oci-image/default.nix {
        inherit system;
      };
    };
}
