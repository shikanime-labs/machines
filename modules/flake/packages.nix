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

          hostsForSystem = lib.filterAttrs (
            _: cfg: cfg.pkgs.system == system
          ) top.self.nixosConfigurations;

          toplevels = lib.mapAttrs' (
            name: cfg: lib.nameValuePair "${name}-toplevel" cfg.config.system.build.toplevel
          ) hostsForSystem;

          sdHosts = [ "fushi" "minish" "nemishi" ];
          sdImages = lib.mapAttrs' (
            name: cfg: lib.nameValuePair "${name}-sd-image" cfg.config.system.build.sdImage
          ) (lib.filterAttrs (name: _: builtins.elem name sdHosts) hostsForSystem);
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
        // toplevels
        // sdImages;
    };
}
