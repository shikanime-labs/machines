{
  modulesPath,
  pkgs,
  ...
}:

{
  imports = [
    "${modulesPath}/profiles/headless.nix"
    ../../modules/nixos/virtualisation/containerdisk.nix
    ../../modules/nixos/profiles/minimal.nix
    ../../modules/nixos/profiles/ai.nix
    ../../modules/nixos/users/automata.nix
  ];

  networking.hostName = "catbox";

  # Fresh OVMF NVRAM each boot: write the systemd-boot entry as a real EFI
  # Boot variable instead of relying on fallback-path detection.
  boot.loader.efi.canTouchEfiVariables = true;

  sops = {
    age = {
      generateKey = true;
      keyFile = "/var/lib/sops-nix/key.txt";
    };
    defaultSopsFile = ../../secrets/catbox.enc.yaml;
    defaultSopsFormat = "yaml";
  };

  containerdisk = {
    name = "ghcr.io/shikanime-labs/machines/catbox";
    settings.LABELS = {
      "org.opencontainers.image.source" = "https://github.com/shikanime-labs/machines";
      "org.opencontainers.image.description" = "catbox KubeVirt containerdisk";
      "org.opencontainers.image.licenses" = "AGPL-3.0-or-later";
    };
  };

  programs.nix-ld = {
    enable = true;
    libraries = [
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    openFirewall = true;
  };

  virtualisation.docker = {
    autoPrune.enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
}
