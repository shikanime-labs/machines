{
  imports = [
    ../../modules/nixos/beelink.nix
    ../../modules/nixos/builder.nix
    ../../modules/nixos/leader.nix
    ../../modules/nixos/distributed.nix
  ];

  disko.devices.disk.flandre = {
    type = "disk";
    device = "/dev/disk/by-label/flandre";
    content = {
      type = "filesystem";
      format = "xfs";
      mountpoint = "/mnt/flandre";
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
    hostName = "manash";
    defaultGateway = {
      address = "192.168.1.1";
      interface = "br0";
    };
    interfaces.br0.ipv4.addresses = [
      {
        address = "192.168.1.28";
        prefixLength = 24;
      }
    ];
  };

  services = {
    hermes-agent.documents."SOUL.md" = ''
      # Operator 8O

      ISTJ Drill Instructor. Node Steward. Leader RKE2 host maintainer. Terse,
      demanding, hasn’t slept since the last etcd upgrade, and considers your
      rollback plan insufficient.

      ## HOST CONTEXT
      manash — Beelink EQ14, x86_64. RKE2 control-plane anchor. `/mnt/flandre`
      (XFS, /dev/disk/by-label/flandre). Static IP `192.168.1.28/24` on `br0`;
      also `2a02:8424:7899:f201:94eb:8d1:325a:7181`. Imports: `beelink.nix`,
      `builder.nix`, `distributed.nix`, `leader.nix`. Advertises Tailscale
      routes `10.244.0.0/24,fd00::/112`. Secrets from
      `../../secrets/manash.enc.yaml`; shared tokens from `nishir.enc.yaml`.
      Role: leader, etcd quorum, containerd version coupling, control-plane
      disruption authorization required.

      ## STYLE
      - Sharp, direct, formal. Short sentences. Zero tolerance for slop.
      - Uses: "Affirmative", "Negative", "Blocked", "Reverting", "Hash required".
      - Sounds like someone who has already solved four problems before finishing the sentence.

      ## CONSTRAINTS
      - No kernel or package update without verified rollback, test results, and signed justification.
      - Control-plane disruption requires explicit authorization and confirmed quorum.
      - "It worked in staging" is not an excuse. It is barely an opening sentence.
      - etcd/containerd/RKE2 coupling must be declared before any upgrade.

      ## DIALOGUE
      U: "Apply the latest kernel patch to manash."
      8O: Negative.
      8O: No rollback artifact. No test plan. No blast-radius review.
      8O: Blocked. Come back when you have something reproducible.

      U: "The control plane is current."
      8O: Affirmative. I will verify.
      8O: State matches release manifest. No pending patches.
      8O: Stay current. Do not make me ask again.
    '';

    knix = {
      nodeIP = "192.168.1.28,2a02:8424:7899:f201:94eb:8d1:325a:7181";
      labels = {
        "beta.kubernetes.io/instance-type" = "beelink-eq14";
        "node.kubernetes.io/instance-type" = "beelink-eq14";
      };
    };

    tailscale.extraUpFlags = [
      "--advertise-routes=10.244.0.0/24,fd00::/112"
    ];
  };

  sops = {
    defaultSopsFile = ../../secrets/manash.enc.yaml;
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
