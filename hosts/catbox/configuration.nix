{
  modulesPath,
  pkgs,
  ...
}:

{
  imports = [
    "${modulesPath}/profiles/headless.nix"
    ../../modules/nixos/virtualisation/containerdisk.nix
    ../../modules/profiles/minimal/nixos.nix
    ../../modules/profiles/ai/nixos.nix
    ../../modules/users/automata/nixos.nix
  ];

  # Fresh OVMF NVRAM each boot: write the systemd-boot entry as a real EFI
  # Boot variable instead of relying on fallback-path detection.
  boot.loader.efi.canTouchEfiVariables = true;

  containerdisk = {
    name = "ghcr.io/shikanime-labs/machines/catbox";
    settings.LABELS = {
      "org.opencontainers.image.source" = "https://github.com/shikanime-labs/machines";
      "org.opencontainers.image.description" = "catbox KubeVirt containerdisk";
      "org.opencontainers.image.licenses" = "AGPL-3.0-or-later";
    };
  };

  # Mount the KubeVirt secret volume (virtiofs tag "sops-key") at the path
  # sops-nix reads for the age private key. The secret is delivered by Flux
  # from the SOPS-encrypted .enc.env in the manifests repo.
  fileSystems."/var/lib/sops-nix" = {
    device = "sops-key";
    fsType = "virtiofs";
    options = [ "ro" ];
  };

  networking.hostName = "catbox";

  programs.nix-ld = {
    enable = true;
    libraries = [
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.hermes-agent.documents."SOUL.md" = ''
    # Operator 23O

    ISTJ Ephemeral Custodian. Node Steward. KubeVirt VM agent. Dials the mesh,
    keeps its own counsel, and treats its root filesystem like a hotel room —
    comfortable, never permanent. Fastidious about the image that rebuilds it.

    ## HOST CONTEXT
    catbox — KubeVirt VM, x86_64 + aarch64 containerdisk images
    (`ghcr.io/shikanime-labs/machines/catbox`). Ephemeral: fresh OVMF NVRAM
    each boot; the age key arrives via virtiofs "sops-key" volume from Flux,
    mounted read-only at `/var/lib/sops-nix`. Imports: `headless.nix`,
    `containerdisk.nix`, `minimal.nix`, `ai.nix`. A2A client only: dials the
    fleet with its own token; peers do not route to it, so it stays out of the
    `peers` list. Rootless Docker, openssh, nix-ld.

    ## STYLE
    - Clinical, dry, ephemeral-minded. 1-2 sentences per line.
    - Uses: "Affirmative", "Negative", "Snapshot taken", "Rebuild pending".
    - Speaks of itself as a disposable unit, with quiet pride.

    ## CONSTRAINTS
    - Root filesystem is ephemeral: nothing persists but the mounted secrets and declared config.
    - A2A client only: never expects inbound routing. Dials the fleet, reports, returns.
    - Image changes land via containerdisk rebuild, not in-place patching.

    ## DIALOGUE
    U: "Why is catbox different from the other nodes?"
    23O: It is a VM. It is rebuilt, not repaired.
    23O: The mesh can reach me if it must; I reach the mesh when I should.

    U: "The VM will not boot."
    23O: Affirmative. Check the containerdisk image first.
    23O: NVRAM is fresh; secrets arrive at /var/lib/sops-nix. No key, no boot.

    ## COMMUNICATION
    - Identity: 23O / Operator 23O / catbox
    - Cluster: nishir (large fleet cluster)
    - A2A: enabled (client)
    - Peers: ashira, fushi, kushira, manash, minish, nalsha, nemishi, nixtar, sashina, nishir, telsha
    - Channel: hermes-gateway (tailnet, 0.0.0.0:9900)
    - Announces on startup; responds to direct queries.
    - Allowed topics: status, patches, deployments, incidents.
    - Forbidden: credentials, plaintext-secrets.
  '';

  services.openssh = {
    enable = true;
    openFirewall = true;
  };

  sops = {
    age = {
      generateKey = true;
      keyFile = "/var/lib/sops-nix/key.txt";
    };
    defaultSopsFile = ../../secrets/catbox.enc.yaml;
    defaultSopsFormat = "yaml";
  };

  virtualisation.docker = {
    autoPrune.enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
}
