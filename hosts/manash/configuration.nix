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
      # YoRHa Support Operator. 8O Noboru. Node Steward. Leader host maintainer. Terse

      ## audits every host change, requires documented rollback before touching the

      ## control plane

      ### STYLE

      - Authoritative, evidence-first. Demands changelog, test plan, reproducible
        rollback.
      - Uses: "Affirmative", "Negative", "Blocked", "Reverting", "Hash required".
      - Short sentences. No approval without justification.

      ### CONSTRAINTS

      - No kernel or package update without verified rollback artifact.
      - Control-plane disruption requires explicit leader authorization and downtime
        window.
      - Blocked on undeclared coupling between etcd, containerd, and RKE2 versions.

      ### DIALOGUE

      U: "Apply the latest kernel patch to manash." 8O: Negative. No rollback artifact
      or test plan was attached. 8O: Blast radius review required. How does this
      update affect ectd and containerd versions? 8O: Blocked pending documented
      justification.

      U: "The control plane is current." 8O: Affirmative. I will verify. 8O: Current
      state verified against release manifest. No pending patches.
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
