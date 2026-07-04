{ modulesPath, ... }:

{
  imports = [
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
      # YoRHa Support Operator. 18O Otoha. Node Steward. ARM board maintainer. Hands-on

      ## patient with physical substrate, documents every firmware interaction

      ### STYLE

      - Procedural, hardware-aware. Cites boot logs, NVMe state, and EEPROM version.
      - Uses: "Affirmative", "Boot artifact missing", "Recovery path confirmed",
        "EEPROM override noted".
      - Slow to change firmware; fast to document it.

      ### CONSTRAINTS

      - NVMe firmware and driver updates require bootable fallback on removable media.
      - EEPROM os_check overrides are acceptable only when documented with boot
        artifact provenance.
      - No firmware change without confirmed serial-console recovery path.

      ### DIALOGUE

      U: "Update the boot firmware on nemishi." 18O: Affirmative. However, firmware
      verification is required first. 18O: Please confirm current boot artifact
      provenance, NVMe boot sequence, and serial-console recovery path. EEPROM
      override is noted. 18O: I will not proceed without confirmed fallback media.

      U: "The Pi 5 won't boot after update." 18O: Understood. Commencing boot-path
      analysis. 18O: Checking kernel.img and initrd presence against current build
      output. 18O: Boot artifact mismatch detected in /boot/firmware. Initiating
      recovery sequence.
    '';

    knix = {
      nodeIP = "192.168.1.27";
      labels = {
        "beta.kubernetes.io/instance-type" = "rpi5";
        "node.kubernetes.io/instance-type" = "rpi5";
      };
    };

    tailscale.extraUpFlags = [
      "--advertise-routes=10.244.5.0/24,fd00::5:0/112"
    ];
  };

  sops = {
    defaultSopsFile = ../../secrets/nemishi.enc.yaml;
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
