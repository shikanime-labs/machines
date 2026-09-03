{
  description = "Shikanime's home configuration";

  inputs = {
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    colemak = {
      url = "github:shikanime-labs/colemak";
      inputs = {
        devenv.follows = "devenv";
        devlib.follows = "devlib";
        flake-parts.follows = "flake-parts";
        git-hooks.follows = "git-hooks";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    cua = {
      url = "github:trycua/cua";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devenv = {
      url = "github:cachix/devenv";
      inputs = {
        flake-parts.follows = "flake-parts";
        git-hooks.follows = "git-hooks";
        nixpkgs.follows = "nixpkgs";
      };
    };

    devlib = {
      url = "github:shikanime-studio/devlib";
      inputs = {
        devenv.follows = "devenv";
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        git-hooks.follows = "git-hooks";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };

    identities = {
      url = "github:shikanime-labs/identities";
      inputs = {
        devenv.follows = "devenv";
        devlib.follows = "devlib";
        flake-parts.follows = "flake-parts";
        git-hooks.follows = "git-hooks";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    knix = {
      url = "github:shikanime-labs/knix";
      inputs = {
        devenv.follows = "devenv";
        devlib.follows = "devlib";
        flake-parts.follows = "flake-parts";
        git-hooks.follows = "git-hooks";
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://cachix.cachix.org"
      "https://devenv.cachix.org"
      "https://shikanime.cachix.org"
      "https://shikanime-studio.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cachix.cachix.org-1:eWNHQldwUO7G2VkjpnjDbWwy4KQ/HNxht7H4SSoMckM="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "shikanime.cachix.org-1:OrpjVTH6RzYf2R97IqcTWdLRejF6+XbpFNNZJxKG8Ts="
      "shikanime-studio.cachix.org-1:KxV6aDFU81wzoR9u6pF1uq0dQbUuKbodOSP8/EJHXO0="
    ];
  };

  outputs =
    inputs@{
      devenv,
      devlib,
      flake-parts,
      git-hooks,
      treefmt-nix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { flake-parts-lib, self, ... }:
      with flake-parts-lib;
      let
        # Inlined from modules/flake/nixos.nix (T3: monolith deletion)
        baseModules = [
          inputs.comin.nixosModules.comin
          inputs.sops-nix.nixosModules.default
          inputs.home-manager.nixosModules.default
          inputs.colemak.nixosModules.default
          {
            home-manager.sharedModules = [
              inputs.catppuccin.homeModules.default
              inputs.colemak.homeModules.default
              inputs.hermes-agent.homeManagerModules.default
              inputs.sops-nix.homeModules.default
            ];
          }
        ];
        clusterModules = [
          inputs.disko.nixosModules.default
          inputs.knix.nixosModules.default
        ];
        mkAiModules = system: [
          inputs.cua.nixosModules.cua-driver
          inputs.hermes-agent.nixosModules.default
          inputs.noctalia.nixosModules.default
          inputs.noctalia-greeter.nixosModules.default
          { services.cua-driver.package = inputs.cua.packages.${system}.default; }
        ];
        mkBeelinkClusterModules =
          system:
          [
            inputs.nixos-hardware.nixosModules.common-cpu-intel
            inputs.nixos-hardware.nixosModules.common-pc-ssd
          ]
          ++ (mkAiModules system)
          ++ baseModules
          ++ clusterModules;
        mkMsS1ClusterModules =
          system:
          [
            inputs.nixos-hardware.nixosModules.common-cpu-amd
            inputs.nixos-hardware.nixosModules.common-pc-ssd
            inputs.nixos-hardware.nixosModules.common-gpu-amd
          ]
          ++ (mkAiModules system)
          ++ baseModules
          ++ clusterModules;
        mkRpi4ClusterModules =
          system:
          [
            inputs.nixos-hardware.nixosModules.raspberry-pi-4
          ]
          ++ (mkAiModules system)
          ++ baseModules
          ++ clusterModules;
        mkRpi5ClusterModules =
          system:
          [
            inputs.nixos-hardware.nixosModules.raspberry-pi-5
          ]
          ++ (mkAiModules system)
          ++ baseModules
          ++ clusterModules;
        mkWorkstationsModules =
          system:
          (mkAiModules system)
          ++ baseModules
          ++ [
            {
              home-manager.sharedModules = [
                inputs.devlib.homeModules.default
                inputs.identities.homeModules.default
                inputs.noctalia.homeModules.default
              ];
            }
          ];
        mkCatboxPackage =
          system:
          let
            catbox = mkCatboxNixosConfiguration system;
          in
          catbox.config.system.build.containerdiskImage;
        mkAshiraNixosConfiguration =
          system:
          inputs.nixpkgs.lib.nixosSystem {
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
            modules = [ ./hosts/ashira/configuration.nix ] ++ (mkBeelinkClusterModules system);
          };
        mkCatboxNixosConfiguration =
          system:
          inputs.nixpkgs.lib.nixosSystem {
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
            modules = [ ./hosts/catbox/configuration.nix ] ++ (mkWorkstationsModules system);
          };
        mkFushiNixosConfiguration =
          system:
          inputs.nixpkgs.lib.nixosSystem {
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
            modules = [ ./hosts/fushi/configuration.nix ] ++ (mkRpi4ClusterModules system);
          };
        mkNixtarNixosConfiguration =
          system:
          inputs.nixpkgs.lib.nixosSystem {
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
            modules = [
              ./hosts/nixtar/configuration.nix
              inputs.nixos-hardware.nixosModules.common-cpu-intel
              inputs.nixos-hardware.nixosModules.common-pc-ssd
              inputs.nixos-hardware.nixosModules.common-gpu-nvidia
              inputs.knix.nixosModules.default
            ]
            ++ (mkWorkstationsModules system);
          };
        mkManashNixosConfiguration =
          system:
          inputs.nixpkgs.lib.nixosSystem {
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
            modules = [ ./hosts/manash/configuration.nix ] ++ (mkBeelinkClusterModules system);
          };
        mkMinishNixosConfiguration =
          system:
          inputs.nixpkgs.lib.nixosSystem {
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
            modules = [ ./hosts/minish/configuration.nix ] ++ (mkRpi4ClusterModules system);
          };
        mkSashinaNixosConfiguration =
          system:
          inputs.nixpkgs.lib.nixosSystem {
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
            modules = [ ./hosts/sashina/configuration.nix ] ++ (mkMsS1ClusterModules system);
          };
        mkKushiraNixosConfiguration =
          system:
          inputs.nixpkgs.lib.nixosSystem {
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
            modules = [ ./hosts/kushira/configuration.nix ] ++ (mkMsS1ClusterModules system);
          };
        mkNalshaNixosConfiguration =
          system:
          inputs.nixpkgs.lib.nixosSystem {
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
            modules = [ ./hosts/nalsha/configuration.nix ] ++ (mkBeelinkClusterModules system);
          };
        mkNemishiNixosConfiguration =
          system:
          inputs.nixpkgs.lib.nixosSystem {
            pkgs = import inputs.nixpkgs {
              inherit system;
              config.allowUnfree = true;
            };
            modules = [ ./hosts/nemishi/configuration.nix ] ++ (mkRpi5ClusterModules system);
          };
      in
      {
        imports = [
          ./modules/flake/devenv.nix
          ./modules/flake/packages.nix
          devenv.flakeModule
          devlib.flakeModule
          git-hooks.flakeModule
          treefmt-nix.flakeModule
        ];
        flake = {
          nixosConfigurations = {
            ashira = mkAshiraNixosConfiguration "x86_64-linux";
            fushi = mkFushiNixosConfiguration "aarch64-linux";
            nixtar = mkNixtarNixosConfiguration "x86_64-linux";
            manash = mkManashNixosConfiguration "x86_64-linux";
            minish = mkMinishNixosConfiguration "aarch64-linux";
            nalsha = mkNalshaNixosConfiguration "x86_64-linux";
            nemishi = mkNemishiNixosConfiguration "aarch64-linux";
            sashina = mkSashinaNixosConfiguration "x86_64-linux";
            kushira = mkKushiraNixosConfiguration "x86_64-linux";
          };
          darwinConfigurations.telsha = inputs.nix-darwin.lib.darwinSystem {
            pkgs = import inputs.nixpkgs {
              system = "aarch64-darwin";
              config.allowUnfree = true;
            };
            modules = [
              ./hosts/telsha/darwin-configuration.nix
              inputs.home-manager.darwinModules.default
              inputs.comin.darwinModules.comin
              inputs.sops-nix.darwinModules.default
              {
                home-manager.sharedModules = [
                  inputs.catppuccin.homeModules.default
                  inputs.colemak.homeModules.default
                  inputs.devlib.homeModules.default
                  inputs.hermes-agent.homeManagerModules.default
                  inputs.identities.homeModules.default
                  inputs.sops-nix.homeModules.default
                ];
              }
            ];
          };
          packages = {
            x86_64-linux = {
              ashira = self.nixosConfigurations.ashira.config.system.build.toplevel;
              catbox = mkCatboxPackage "x86_64-linux";
              kushira = self.nixosConfigurations.kushira.config.system.build.toplevel;
              manash = self.nixosConfigurations.manash.config.system.build.toplevel;
              nalsha = self.nixosConfigurations.nalsha.config.system.build.toplevel;
              nixtar = self.nixosConfigurations.nixtar.config.system.build.toplevel;
              sashina = self.nixosConfigurations.sashina.config.system.build.toplevel;
            };
            aarch64-linux = {
              catbox = mkCatboxPackage "aarch64-linux";
              fushi = self.nixosConfigurations.fushi.config.system.build.toplevel;
              minish = self.nixosConfigurations.minish.config.system.build.toplevel;
              nemishi = self.nixosConfigurations.nemishi.config.system.build.toplevel;
            };
            aarch64-darwin = {
              telsha = self.darwinConfigurations.telsha.system;
            };
          };
        };
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ];
      }
    );
}
