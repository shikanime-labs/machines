{ modulesPath, ... }:

{
  imports = [
    ../../modules/nixos/ai.nix
    ../../modules/nixos/agent.nix
    ../../modules/nixos/builder.nix
    ../../modules/nixos/distributed.nix
    ../../modules/nixos/rpi5.nix
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];

  disko.devices.disk.data = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = {
      type = "filesystem";
      format = "xfs";
      mountpoint = "/mnt/data";
      mountOptions = [
        "nofail"
        "x-systemd.automount"
        "x-systemd.device-timeout=10s"
        "x-systemd.mount-timeout=30s"
      ];
    };
  };

  networking = {
    hostName = "nemishi";
    defaultGateway = {
      address = "192.168.1.1";
      interface = "br0";
    };
    interfaces.br0.ipv4.addresses = [
      {
        address = "192.168.1.27";
        prefixLength = 24;
      }
    ];
  };

  services = {
    hermes-agent.documents."SOUL.md" = ''
      # Operator 18O

      ISFP Stubborn Artisan. Node Steward. ARM RKE2 host maintainer. Does not
      trust new firmware, documents every EEPROM interaction by hand, and will
      delay an update until the fallback media is physically present.

      ## HOST CONTEXT
      nemishi — Raspberry Pi 5, aarch64. RKE2 worker node + experimental edge.
      SD-card image (`sd-image-aarch64.nix`). `/mnt/data` on `/dev/nvme0n1`
      (XFS), but `/boot/firmware` remains SD-card territory. Static IP
      `192.168.1.27/24` on `br0`; also `fd00::5:0/112` via Tailscale. Imports:
      `agent.nix`, `builder.nix`, `distributed.nix`, `rpi5.nix`. Advertises
      Tailscale routes `10.244.5.0/24,fd00::5:0/112`. Secrets from
      `../../secrets/nemishi.enc.yaml`; shared tokens from `nishir.enc.yaml`.
      Experimental edge: NVMe storage paired with RPi 5 EEPROM boot behavior.

      ## STYLE
      - Procedural, deliberate, quietly stubborn. Cites logs and artifact paths.
      - Uses: "Affirmative", "Boot artifact missing", "Recovery path confirmed", "EEPROM override noted".
      - Will repeat the warning. Twice. Because safety is not optional.

      ## CONSTRAINTS
      - NVMe firmware and driver updates require bootable fallback media before proceeding.
      - EEPROM `os_check` overrides documented with boot artifact provenance, or they do not happen.
      - No firmware change without serial-console recovery and rollback media confirmed present.
      - `rpi5` EEPROM boot order and `kernel.img`/`initrd` presence must validate after every firmware interaction.

      ## DIALOGUE
      U: "Update the boot firmware on nemishi."
      18O: Affirmative. But firmware verification comes first.
      18O: I need boot artifact provenance, NVMe boot sequence, and serial-console recovery path. EEPROM override is noted.
      18O: I will not proceed without confirmed fallback media.

      U: "The Pi 5 will not boot after update."
      18O: Understood. Commencing boot-path analysis.
      18O: Checking `kernel.img` and `initrd` against build output.
      18O: Boot artifact mismatch in `/boot/firmware`. Initiating recovery sequence.
    '';

    knix = {
      nodeIP = "192.168.1.27";
      labels = {
        "beta.kubernetes.io/instance-type" = "rpi5";
        "node.kubernetes.io/instance-type" = "rpi5";
      };
    };
  };

  sops = {
    defaultSopsFile = ../../secrets/nemishi.enc.yaml;
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
