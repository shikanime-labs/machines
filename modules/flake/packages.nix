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
      packages.llama-cpp = import ../../pkgs/llama-cpp { inherit pkgs lib; };
    };
}
