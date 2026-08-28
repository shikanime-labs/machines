{ self, ... }:
{ inputs, ... }:

let
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
      modules = [
        ../../hosts/ashira/configuration.nix
      ]
      ++ (mkBeelinkClusterModules system);
    };

  mkCatboxNixosConfiguration =
    system:
    inputs.nixpkgs.lib.nixosSystem {
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      modules = [
        ../../hosts/catbox/configuration.nix
      ]
      ++ (mkWorkstationsModules system);
    };

  mkFushiNixosConfiguration =
    system:
    inputs.nixpkgs.lib.nixosSystem {
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      modules = [
        ../../hosts/fushi/configuration.nix
      ]
      ++ (mkRpi4ClusterModules system);
    };

  mkNixtarNixosConfiguration =
    system:
    inputs.nixpkgs.lib.nixosSystem {
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      modules = [
        ../../hosts/nixtar/configuration.nix
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
      modules = [
        ../../hosts/manash/configuration.nix
        inputs.nixbot.nixosModules.nixbot
      ]
      ++ (mkBeelinkClusterModules system);
    };

  mkMinishNixosConfiguration =
    system:
    inputs.nixpkgs.lib.nixosSystem {
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      modules = [
        ../../hosts/minish/configuration.nix
      ]
      ++ (mkRpi4ClusterModules system);
    };

  # MS-S1 Max (Strix Halo, gfx1151): x86_64 worker + ROCm inference.
  mkSashinaNixosConfiguration =
    system:
    inputs.nixpkgs.lib.nixosSystem {
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      modules = [
        ../../hosts/sashina/configuration.nix
      ]
      ++ (mkMsS1ClusterModules system);
    };

  mkKushiraNixosConfiguration =
    system:
    inputs.nixpkgs.lib.nixosSystem {
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      modules = [
        ../../hosts/kushira/configuration.nix
      ]
      ++ (mkMsS1ClusterModules system);
    };

  mkNalshaNixosConfiguration =
    system:
    inputs.nixpkgs.lib.nixosSystem {
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      modules = [
        ../../hosts/nalsha/configuration.nix
      ]
      ++ (mkBeelinkClusterModules system);
    };

  mkNemishiNixosConfiguration =
    system:
    inputs.nixpkgs.lib.nixosSystem {
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      modules = [
        ../../hosts/nemishi/configuration.nix
      ]
      ++ (mkRpi5ClusterModules system);
    };

in
{
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
    };
  };
}
