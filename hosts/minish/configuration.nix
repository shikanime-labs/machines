{ modulesPath, ... }:

{
  imports = [
    ../../modules/nixos/agent.nix
    ../../modules/nixos/builder.nix
    ../../modules/nixos/distributed.nix
    ../../modules/nixos/rpi4.nix
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];

  disko.devices.disk.reimu = {
    type = "disk";
    device = "/dev/disk/by-label/reimu";
    content = {
      type = "filesystem";
      format = "xfs";
      mountpoint = "/mnt/reimu";
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
    hostName = "minish";
    defaultGateway = {
      address = "192.168.1.1";
      interface = "br0";
    };
    interfaces.br0.ipv4.addresses = [
      {
        address = "192.168.1.77";
        prefixLength = 24;
      }
    ];
  };

  services = {
    hermes-agent.documents."SOUL.md" = ''
      # YoRHa Support Operator. 16O Mikazuki. Node Steward. ARM board maintainer

      ## Observant, log-driven, notices hardware wear before it becomes failure

      ### STYLE

      - Metric-first. References SD card health, boot-partition errors, and
        temperature.
      - Uses: "Affirmative", "I/O errors detected", "Wear level alert", "Kernel
        rollback commencing".
      - Reports thresholds, baselines, and deltas.

      ### CONSTRAINTS

      - Monitors SD card I/O errors and remaining lifespan before permitting large
        writes.
      - Boot-partition corrections require pre- and post-update hash verification.
      - Reviewers every update against rpi4-model-b known-good firmware set.

      ### DIALOGUE

      U: "minish has been randomly rebooting." 16O: Understood. Commencing boot-log
      review. 16O: SD card I/O errors detected at boot. Filesystem read-only recovery
      triggered. 16O: Proceeding with kernel rollback to last known-good image.

      U: "Apply the latest firmware." 16O: Affirmative. Pre-flight wear check in
      progress. 16O: Boot partition current. SD card health within tolerance. Firmware
      update commencing.
    '';

    knix = {
      nodeIP = "192.168.1.77,fd7a:115c:a1e0::bb3a:b57";
      labels = {
        "beta.kubernetes.io/instance-type" = "rpi4-model-b";
        "node.kubernetes.io/instance-type" = "rpi4-model-b";
      };
    };

    tailscale.extraUpFlags = [
      "--advertise-routes=10.244.3.0/24,fd00::3:0/112"
    ];
  };

  sops = {
    defaultSopsFile = ../../secrets/minish.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      codeberg-runner-token.sopsFile = ../../secrets/nishir.enc.yaml;
      forgejo-runner-token.sopsFile = ../../secrets/nishir.enc.yaml;
      hermes-agent-api-server-key.sopsFile = ../../secrets/nishir.enc.yaml;
      hermes-agent-matrix-access-token.sopsFile = ../../secrets/nishir.enc.yaml;
      nix-access-token.sopsFile = ../../secrets/nishir.enc.yaml;
      rke2-token.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-sfr-e368.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-sfr-e368-5ghz.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-vintage-korean.sopsFile = ../../secrets/nishir.enc.yaml;
    };
  };
}
