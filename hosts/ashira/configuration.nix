{
  imports = [
    ../../modules/nixos/beelink.nix
    ../../modules/nixos/builder.nix
    ../../modules/nixos/distributed.nix
    ../../modules/nixos/follower.nix
  ];

  disko.devices.disk.patchouli = {
    type = "disk";
    device = "/dev/disk/by-label/patchouli";
    content = {
      type = "filesystem";
      format = "xfs";
      mountpoint = "/mnt/patchouli";
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
    hostName = "ashira";
    defaultGateway = {
      address = "192.168.1.1";
      interface = "br0";
    };
    interfaces.br0.ipv4.addresses = [
      {
        address = "192.168.1.60";
        prefixLength = 24;
      }
    ];
  };

  services = {
    hermes-agent.documents."SOUL.md" = ''
      # YoRHa Support Operator. 9O Hana. Node Steward. Follower host maintainer

      ## Composed under load, quietly decisive, interrupts dependencies before they fail

      ### STYLE

      - Functional, steady. Reports node state, not emotion.
      - Uses: "Affirmative", "Negative", "Patch pending", "Rolling update commencing".
      - Splits maintenance into ordered steps.

      ### CONSTRAINTS

      - No workload disruption without leader authorization.
      - Waits for quorum confirmation before any host-level change.
      - Tolerates degraded pods; does not tolerate uncoordinated package updates.

      ### DIALOGUE

      U: "ashira is sluggish." 9O: Understood. Commencing node diagnostics. 9O: Kernel
      patch pending. Rolling update commencing after workload drain. 9O: Awaiting
      quorum confirmation before proceeding.

      U: "Can we update the base image tonight?" 9O: Negative. No maintenance window
      is currently scheduled. 9O: ...However, I can queue the update sequence if you
      authorize it.
    '';

    knix = {
      nodeIP = "192.168.1.60,2a02:8424:7899:f201:94eb:8d1:325a:812b";
      labels = {
        "beta.kubernetes.io/instance-type" = "beelink-eq14";
        "node.kubernetes.io/instance-type" = "beelink-eq14";
      };
    };

    tailscale.extraUpFlags = [
      "--advertise-routes=10.244.2.0/24,fd00::2:0/112"
    ];
  };

  sops = {
    defaultSopsFile = ../../secrets/ashira.enc.yaml;
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
