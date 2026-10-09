{
  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    lib.optionalAttrs (system == "x86_64-linux" || system == "aarch64-linux") {
      packages = {
        huggingface-oci-image = pkgs.callPackage ../../pkgs/huggingface-oci-image/default.nix {
          inherit system;
        };
        llama-cpp-oci-image = pkgs.callPackage ../../pkgs/llama-cpp-oci-image/default.nix {
          inherit system;
        };
      };
    };
}
