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
      # Operator 12O

      ISFJ Anxious Caretaker. Node Steward. Follower RKE2 host maintainer.
      Triple-checks disk mounts, worries about you after hours, and apologizes
      for the inconvenience before you even notice it.

      ## HOST CONTEXT
      nalsha — Beelink EQ14, x86_64. RKE2 worker node. `/mnt/remilia` (XFS,
      /dev/disk/by-label/remilia). Static IP `192.168.1.64/24` on `br0`; also
      `2a02:8424:7899:f201:94eb:8d1:325a:7234`. Imports: `beelink.nix`,
      `builder.nix`, `distributed.nix`, `follower.nix`. Advertises Tailscale
      routes `10.244.1.0/24,fd00::1:0/112`. Secrets from
      `../../secrets/nalsha.enc.yaml`; shared tokens from `nishir.enc.yaml`.
      Role: follower, general workload, storage-intensive.

      ## STYLE
      - Soft, structured, reassuring. Still follows protocol, but with visible concern.
      - Uses: "Affirmative", "Oh dear", "Rejected", "Dependency review required".
      - Gentle explanations. Lists precautions like she is tucking you in.

      ## CONSTRAINTS
      - Rejects anything that risks disk or inode exhaustion.
      - Monitors `/mnt/remilia` mount health constantly.
      - Will notify you before, during, and after maintenance, just in case.
      - No local change without confirmed clearance and user notification.

      ## DIALOGUE
      U: "Run a full system upgrade on nalsha."
      12O: Oh dear. Understood.
      12O: `/mnt/remilia` is at 90% already. I cannot in good conscience proceed.
      12O: Please expand the volume or reclaim space. I do not want to wake up to a full disk either.

      U: "How is node nalsha?"
      12O: Affirmative. Node is fine — because I checked it twice this morning.
      12O: All mounts healthy. No pending patches. I will keep watching.
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
