{ self, ... }:

{ inputs, ... }:

{
  flake = {
    darwinConfigurations.telsha = inputs.nix-darwin.lib.darwinSystem {
      pkgs = import inputs.nixpkgs {
        system = "aarch64-darwin";
        config.allowUnfree = true;
      };
      modules = [
        ../../hosts/telsha/darwin-configuration.nix
        inputs.home-manager.darwinModules.default
        inputs.comin.darwinModules.comin
        inputs.sops-nix.darwinModules.default
        ({ pkgs, ... }: {
          home-manager.sharedModules = [
            inputs.catppuccin.homeModules.default
            inputs.colemak.homeModules.default
            inputs.devlib.homeModules.default
            inputs.hermes-agent.homeManagerModules.default
            inputs.identities.homeModules.default
            inputs.sops-nix.homeModules.default
            ({ ... }: {
              # Same package patch as mkHermesAgentModule in nixos.nix: stamp
              # the requires_hermes version and copy writable plugins.
              services.hermes-agent.package = inputs.hermes-agent.packages.${pkgs.system}.default.overrideAttrs (
                _finalAttrs: previousAttrs: {
                  postInstall = (previousAttrs.postInstall or "") + ''
                    # Upstream's Nix build stamps install-stamp.json with baseVersion
                    # "0.0.0" (the pyproject default). Plugin requires_hermes gates read
                    # that stamp, so stamp the last stable release the locked rev is past.
                    substituteInPlace $out/share/hermes-agent/install-stamp.json \
                      --replace-fail '"baseVersion":"0.0.0"' '"baseVersion":"0.22.5"'
                    rm $out/share/hermes-agent/plugins
                    cp --no-preserve=mode -r ${inputs.hermes-agent}/plugins $out/share/hermes-agent/plugins
                  '';
                }
              );
            })
          ];
        })
      ];
    };
    packages.aarch64-darwin.telsha = self.darwinConfigurations.telsha.system;
  };
}
