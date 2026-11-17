top@{ ... }:
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
        }
        // lib.optionalAttrs (system == "aarch64-linux") {
          fushi-toplevel = top.self.nixosConfigurations.fushi.config.system.build.toplevel;
          minish-toplevel = top.self.nixosConfigurations.minish.config.system.build.toplevel;
          nemishi-toplevel = top.self.nixosConfigurations.nemishi.config.system.build.toplevel;
        };
    };
}
