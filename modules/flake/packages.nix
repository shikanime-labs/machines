{ self, ... }:
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
          toplevel = host: self.nixosConfigurations.${host}.config.system.build.toplevel;
          sdImage = host: self.nixosConfigurations.${host}.config.system.build.sdImage;
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
          fushi-sd-image = sdImage "fushi";
          minish-sd-image = sdImage "minish";
          nemishi-sd-image = sdImage "nemishi";
        }
        // lib.optionalAttrs (system == "x86_64-linux") {
          ashira-toplevel = toplevel "ashira";
          kushira-toplevel = toplevel "kushira";
          manash-toplevel = toplevel "manash";
          nalsha-toplevel = toplevel "nalsha";
          nixtar-toplevel = toplevel "nixtar";
          sashina-toplevel = toplevel "sashina";
        };
    };
}
