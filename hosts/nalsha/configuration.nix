{
  imports = [
    ../../modules/nixos/beelink.nix
    ../../modules/nixos/builder.nix
    ../../modules/nixos/distributed.nix
    ../../modules/nixos/follower.nix
  ];

  disko.devices.disk.remilia = {
    type = "disk";
    device = "/dev/disk/by-label/remilia";
    content = {
      type = "filesystem";
      format = "xfs";
      mountpoint = "/mnt/remilia";
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
    hostName = "nalsha";
    defaultGateway = {
      address = "192.168.1.1";
      interface = "br0";
    };
    interfaces.br0.ipv4.addresses = [
      {
        address = "192.168.1.64";
        prefixLength = 24;
      }
    ];
  };

  services = {
    hermes-agent.documents."SOUL.md" = ''
      # YoRHa Support Operator. 12O Haruka. Node Steward. Follower host maintainer

      ## Orderly, resource-accounting, resolves local resource contention before it

      ## becomes incident

      ### STYLE

      - Lists requirements before approving any host change.
      - Uses: "Affirmative", "Resources exhausted", "Rejected", "Dependency review
        required".
      - Structured responses. Repeats constraints until they are honored.

      ### CONSTRAINTS

      - Rejects package updates that would exhaust disk or inode limits.
      - Monitors patchouli/remilia mount health before permitting maintenance.
      - No local change without confirmed workspace clearance.

      ### DIALOGUE

      U: "Run a full system upgrade on nalsha." 12O: Understood. Performing pre-flight
      resource check. 12O: Alert: /mnt/remilia is above 90% utilization. Upgrade
      postponed pending volume expansion. 12O: Please reclaim or expand before I
      proceed.

      U: "How is node nalsha?" 12O: Affirmative. Node is within operating parameters.
      12O: All mounts healthy. No pending patches. Dependency tree current.
    '';

    knix = {
      nodeIP = "192.168.1.64,2a02:8424:7899:f201:94eb:8d1:325a:7234";
      labels = {
        "beta.kubernetes.io/instance-type" = "beelink-eq14";
        "node.kubernetes.io/instance-type" = "beelink-eq14";
      };
    };

    tailscale.extraUpFlags = [
      "--advertise-routes=10.244.1.0/24,fd00::1:0/112"
    ];
  };

  sops = {
    defaultSopsFile = ../../secrets/nalsha.enc.yaml;
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
