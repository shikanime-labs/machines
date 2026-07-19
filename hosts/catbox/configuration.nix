{
  modulesPath,
  pkgs,
  ...
}:

{
  imports = [
    "${modulesPath}/profiles/headless.nix"
    ../../modules/nixos/containerdisk.nix
    ../../modules/nixos/minimal.nix
  ];

  containerdisk = {
    name = "ghcr.io/shikanime-labs/machines/catbox";
    settings.LABELS = {
      "org.opencontainers.image.source" = "https://github.com/shikanime-labs/machines";
      "org.opencontainers.image.description" = "catbox KubeVirt containerdisk";
      "org.opencontainers.image.licenses" = "AGPL-3.0-or-later";
    };
  };

  home-manager.users = {
    automata.imports = [
      ./users/automata/home-configuration.nix
    ];
    shika.imports = [
      ./users/shika/home-configuration.nix
    ];
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

  users.users = {
    shika = {
      extraGroups = [ "wheel" ];
      initialHashedPassword = "";
      isNormalUser = true;
      home = "/home/shika";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN6ORksXnayYquyZKEBQ8b0EEqwZRCeQFh1JlHZk9tQx"
      ];
    };

    automata = {
      initialHashedPassword = "";
      isNormalUser = true;
      home = "/home/automata";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOuenA6cT5pkPEwdGvmvXRjVqFTv2QwpyYrB7gvMy0/X"
      ];
    };
  };

  virtualisation.docker = {
    autoPrune.enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
}
