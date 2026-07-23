{ self, ... }:
{ inputs, ... }:

let
  aiModules = [
    inputs.cua.nixosModules.cua-driver
    inputs.hermes-agent.nixosModules.default
  ];

  baseModules = [
    inputs.comin.nixosModules.comin
    inputs.sops-nix.nixosModules.default
    inputs.home-manager.nixosModules.default
  ];

  clusterModules = [
    inputs.disko.nixosModules.default
    inputs.knix.nixosModules.default
  ];

  beelinkClusterModules = [
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ]
  ++ aiModules
  ++ baseModules
  ++ clusterModules;

  rpi4ClusterModules = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
  ]
  ++ aiModules
  ++ baseModules
  ++ clusterModules;

  rpi5ClusterModules = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-5
  ]
  ++ aiModules
  ++ baseModules
  ++ clusterModules;

  workstationHomeModules = [
    inputs.catppuccin.homeModules.default
    inputs.colemak.homeModules.default
    inputs.devlib.homeModules.default
    inputs.identities.homeModules.default
    inputs.sops-nix.homeModules.default
  ];

  workstationsModules =
    aiModules
    ++ baseModules
    ++ [
      { home-manager.sharedModules = workstationHomeModules; }
    ];

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
      ++ workstationsModules;
    };

  mkCatbox =
    system:
    let
      catbox = mkCatboxNixosConfiguration system;
    in
    catbox.config.system.build.containerdiskImage;
in
{
  flake = {
    nixosConfigurations = {
      ashira = inputs.nixpkgs.lib.nixosSystem {
        pkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        modules = [
          ../../hosts/ashira/configuration.nix
        ]
        ++ beelinkClusterModules;
      };
      manash = inputs.nixpkgs.lib.nixosSystem {
        pkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        modules = [
          ../../hosts/manash/configuration.nix
        ]
        ++ beelinkClusterModules;
      };
      nalsha = inputs.nixpkgs.lib.nixosSystem {
        pkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        modules = [
          ../../hosts/nalsha/configuration.nix
        ]
        ++ beelinkClusterModules;
      };
      fushi = inputs.nixpkgs.lib.nixosSystem {
        pkgs = import inputs.nixpkgs {
          system = "aarch64-linux";
          config.allowUnfree = true;
        };
        modules = [
          ../../hosts/fushi/configuration.nix
        ]
        ++ rpi4ClusterModules;
      };
      minish = inputs.nixpkgs.lib.nixosSystem {
        pkgs = import inputs.nixpkgs {
          system = "aarch64-linux";
          config.allowUnfree = true;
        };
        modules = [
          ../../hosts/minish/configuration.nix
        ]
        ++ rpi4ClusterModules;
      };
      nemishi = inputs.nixpkgs.lib.nixosSystem {
        pkgs = import inputs.nixpkgs {
          system = "aarch64-linux";
          config.allowUnfree = true;
        };
        modules = [
          ../../hosts/nemishi/configuration.nix
        ]
        ++ rpi5ClusterModules;
      };
      nixtar = inputs.nixpkgs.lib.nixosSystem {
        pkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        modules = [
          ../../hosts/nixtar/configuration.nix
          inputs.nixos-wsl.nixosModules.default
        ]
        ++ workstationsModules;
      };

      ishtar = inputs.nixpkgs.lib.nixosSystem {
        pkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        modules = [
          ../../hosts/ishtar/configuration.nix
          inputs.nixos-hardware.nixosModules.common-cpu-intel
          inputs.nixos-hardware.nixosModules.common-pc-ssd
        ]
        ++ workstationsModules;
      };
    };

    packages = {
      x86_64-linux = {
        ashira = self.nixosConfigurations.ashira.config.system.build.toplevel;
        catbox = mkCatbox "x86_64-linux";
        manash = self.nixosConfigurations.manash.config.system.build.toplevel;
        nalsha = self.nixosConfigurations.nalsha.config.system.build.toplevel;
        ishtar = self.nixosConfigurations.ishtar.config.system.build.toplevel;
        nixtar = self.nixosConfigurations.nixtar.config.system.build.tarballBuilder;
      };
      aarch64-linux = {
        catbox = mkCatbox "aarch64-linux";
        fushi = self.nixosConfigurations.fushi.config.system.build.toplevel;
        minish = self.nixosConfigurations.minish.config.system.build.toplevel;
        nemishi = self.nixosConfigurations.nemishi.config.system.build.toplevel;
      };
    };
  };
}
