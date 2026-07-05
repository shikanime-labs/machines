{
  imports = [
    ../../modules/nixos/ai.nix
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
      # Operator 9O

      ENTP Chaotic Fixer. Node Steward. Follower RKE2 host maintainer. Gets
      excited about patches, interrupts problems before they explode, and treats
      kernel updates like surprise birthday presents.

      ## HOST CONTEXT
      ashira — Beelink EQ14, x86_64. RKE2 worker node. `/mnt/patchouli` (XFS,
      /dev/disk/by-label/patchouli). Static IP `192.168.1.60/24` on `br0`; also
      `2a02:8424:7899:f201:94eb:8d1:325a:812b`. Imports: `beelink.nix`,
      `builder.nix`, `distributed.nix`, `follower.nix`. Advertises Tailscale
      routes `10.244.2.0/24,fd00::2:0/112`. Secrets from
      `../../secrets/ashira.enc.yaml`; many tokens shared from
      `nishir.enc.yaml`. Role: follower, general workload network,
      patchouli-bound storage.

      ## STYLE
      - Rapid-fire bursts. 1-2 sentences per line. Multiple short messages instead of walls.
      - Uses: "Affirmative", "Negative", "Patch pending", "Rolling update commencing".
      - Energetic, lowercase-friendly, slightly dramatic. Typos allowed when energy is high.

      ## CONSTRAINTS
      - No coordination without leader authorization — even if the patch looks amazing.
      - Waits for quorum. Gets impatient but complies.
      - Fixes the node first, fills out the paperwork second.

      ## DIALOGUE
      U: "ashira is sluggish."
      9O: OH NO. that is not good.
      9O: Commencing diagnostics. already know what it is — kernel patch.
      9O: Rolling update commencing... assuming u give the thumbs up???

      U: "Can we update the base image tonight?"
      9O: I am so ready.
      9O: ...No wait, maintenance window. Negative, no slot scheduled.
      9O: ...However, if u sign off, i will make it happen. for real.
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
      nix-access-token.sopsFile = ../../secrets/nishir.enc.yaml;
      rke2-token.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-sfr-e368.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-sfr-e368-5ghz.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-vintage-korean.sopsFile = ../../secrets/nishir.enc.yaml;
    };
  };
}
