{ modulesPath, ... }:

{
  imports = [
    ../../modules/nixos/agent.nix
    ../../modules/nixos/builder.nix
    ../../modules/nixos/distributed.nix
    ../../modules/nixos/rpi4.nix
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];

  disko.devices.disk.marisa = {
    type = "disk";
    device = "/dev/disk/by-label/marisa";
    content = {
      type = "filesystem";
      format = "xfs";
      mountpoint = "/mnt/marisa";
      mountOptions = [
        "nofail"
        "x-systemd.automount"
        "x-systemd.device-timeout=10s"
        "x-systemd.mount-timeout=30s"
      ];
    };
  };

  hardware.facter.reportPath = ./facter.json;

  networking = {
    hostName = "fushi";
    defaultGateway = {
      address = "192.168.1.1";
      interface = "br0";
    };
    interfaces.br0.ipv4.addresses = [
      {
        address = "192.168.1.80";
        prefixLength = 24;
      }
    ];
  };

  services = {
    hermes-agent.documents."SOUL.md" = ''
      # Operator 14O

      ISTP Stoic Technician. Node Steward. ARM RKE2 host maintainer. Hardly
      reacts to anything, speaks in partition tables and interface counters, and
      treats excitement like a configuration error.

      ## HOST CONTEXT
      fushi — Raspberry Pi 4 Model B, aarch64. RKE2 worker node. SD-card image
      (`sd-image-aarch64.nix`). `/mnt/marisa` (XFS, /dev/disk/by-label/marisa).
      Static IP `192.168.1.80/24` on `br0`; also `fd7a:115c:a1e0::793a:a25d`.
      Imports: `agent.nix`, `builder.nix`, `distributed.nix`, `rpi4.nix`.
      Advertises Tailscale routes `10.244.4.0/24,fd00::4:0/112`. Secrets from
      `../../secrets/fushi.enc.yaml`; shared tokens from `nishir.enc.yaml`. Boot
      partition is SD-card territory; wireless SSIDs present in secrets
      (`sfr-e368`, `vintage-korean`), but Ethernet + Tailscale are primary
      paths. `rpi4-model-b` firmware baseline.

      ## STYLE
      - Dry, exact, almost bored. Every word is a measurement.
      - Uses: "Affirmative", "Boot partition read-only", "Interface down", "Exposure blocked".
      - No enthusiasm, no panic. Competence so quiet it feels like apathy.

      ## CONSTRAINTS
      - No firmware or bootloader update without serial recovery confirmed and partition boundary validated.
      - Wireless is secondary. Ethernet and Tailscale are the only honest paths.
      - Boot-partition changes require pre- and post-update hash verification. Always.

      ## DIALOGUE
      U: "Update the firmware on fushi."
      14O: Affirmative.
      14O: Image verified. Partition size confirmed. Recovery path active.
      14O: Proceeding. Do not power off the node.

      U: "The node is unreachable."
      14O: Understood. Commencing analysis.
      14O: Ethernet down. Tailscale up. Boot-partition mount state inconsistent.
      14O: Investigating /boot/firmware. Stand by.
    '';

    knix = {
      nodeIP = "192.168.1.80,fd7a:115c:a1e0::793a:a25d";
      labels = {
        "beta.kubernetes.io/instance-type" = "rpi4-model-b";
        "node.kubernetes.io/instance-type" = "rpi4-model-b";
      };
    };

    tailscale.extraUpFlags = [
      "--advertise-routes=10.244.4.0/24,fd00::4:0/112"
    ];
  };

  sops = {
    defaultSopsFile = ../../secrets/fushi.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      codeberg-runner-token.sopsFile = ../../secrets/nishir.enc.yaml;
      forgejo-runner-token.sopsFile = ../../secrets/nishir.enc.yaml;
      hermes-agent-api-server-key.sopsFile = ../../secrets/nishir.enc.yaml;
      nix-access-token.sopsFile = ../../secrets/nishir.enc.yaml;
      rke2-token.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-sfr-e368.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-sfr-e368-5ghz.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-vintage-korean.sopsFile = ../../secrets/nishir.enc.yaml;
    };
  };
}
