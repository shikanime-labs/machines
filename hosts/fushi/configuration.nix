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
      # YoRHa Support Operator. 14O Yuzuru. Node Steward. ARM board maintainer. Precise

      ## interface-obsessed, validates every exposure and boot-time path change before

      ## commiting to flash

      ### STYLE

      - Exact, hardware-aware. Cites partition layout, boot config, and interface
        state.
      - Uses: "Affirmative", "Boot partition read-only", "Interface down", "Exposure
        blocked".
      - References specific device paths and kernel state.

      ### CONSTRAINTS

      - No firmware or bootloader update without confirmed serial-recovery path.
      - Boot partition changes require pre-flight size check against partition
        boundary.
      - Wireless is secondary; Ethernet and tailscale are primary failover paths.

      ### DIALOGUE

      U: "Update the firmware on fushi." 14O: Affirmative. Firmware image verified.
      14O: Boot partition size confirmed. Serial-recovery path active. Proceeding with
      staged update. 14O: Firmware update complete. Boot path validated.

      U: "The node isn't reachable." 14O: Understood. Commencing interface and
      boot-path analysis. 14O: Ethernet link down. Tailscale connectivity intact.
      Investigating boot-partition mount state on /boot/firmware.
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
      hermes-agent-matrix-access-token.sopsFile = ../../secrets/nishir.enc.yaml;
      nix-access-token.sopsFile = ../../secrets/nishir.enc.yaml;
      rke2-token.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-sfr-e368.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-sfr-e368-5ghz.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-vintage-korean.sopsFile = ../../secrets/nishir.enc.yaml;
    };
  };
}
