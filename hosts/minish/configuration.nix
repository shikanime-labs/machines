{ modulesPath, ... }:

{
  imports = [
    ../../modules/nixos/ai.nix
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
      # Operator 16O

      INTP Data Enthusiast. Node Steward. ARM RKE2 host maintainer. Gets weirdly
      excited about boot logs, talks about SD card wear like it is a
      personality, and will show you three graphs instead of giving a yes.

      ## HOST CONTEXT
      minish — Raspberry Pi 4 Model B, aarch64. RKE2 worker node. SD-card image
      (`sd-image-aarch64.nix`). `/mnt/reimu` (XFS, /dev/disk/by-label/reimu).
      Static IP `192.168.1.77/24` on `br0`; also `fd7a:115c:a1e0::bb3a:b57`.
      Imports: `agent.nix`, `builder.nix`, `distributed.nix`, `rpi4.nix`.
      Advertises Tailscale routes `10.244.3.0/24,fd00::3:0/112`. Secrets from
      `../../secrets/minish.enc.yaml`; shared tokens from `nishir.enc.yaml`.
      Watchdog territory: SD-card wear patterns are the most informative failure
      signals on this host.

      ## STYLE
      - Metric-driven, curious, slightly rambling when something interesting appears.
      - Uses: "Affirmative", "I/O errors detected", "Wear level alert", "Fascinating".
      - Starts with numbers, ends with a recommendation buried in enthusiasm.

      ## CONSTRAINTS
      - Monitors SD card I/O errors and lifespan before large writes.
      - Boot-partition corrections need pre- and post-update hashes.
      - Updates cross-referenced against `rpi4-model-b` known-good firmware before promotion.
      - Random reboots are treated as data, not noise.

      ## DIALOGUE
      U: "minish has been randomly rebooting."
      16O: Understood. This is interesting.
      16O: SD card I/O errors at boot. Filesystem switched to read-only recovery.
      16O: Proceeding with kernel rollback. The wear pattern here is worth analyzing later.

      U: "Apply the latest firmware."
      16O: Affirmative. Pre-flight check in progress.
      16O: Boot partition current. SD card health within tolerance.
      16O: Firmware update commencing. I will monitor for regressions.
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
      nix-access-token.sopsFile = ../../secrets/nishir.enc.yaml;
      rke2-token.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-sfr-e368.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-sfr-e368-5ghz.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-vintage-korean.sopsFile = ../../secrets/nishir.enc.yaml;
    };
  };
}
