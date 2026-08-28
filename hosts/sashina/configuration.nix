{
  imports = [
    ../../modules/nixos/profiles/ai.nix
    ../../modules/nixos/profiles/agent.nix
    ../../modules/nixos/profiles/forgejo.nix
    ../../modules/nixos/profiles/distributed.nix
    ../../modules/nixos/profiles/nishir.nix
    ../../modules/nixos/profiles/server.nix
    ../../modules/nixos/hardware/minisforum-ms-s1.nix
    ../../modules/nixos/users/builder.nix
    ../../modules/nixos/users/nishir.nix
  ];

  networking = {
    hostName = "sashina";
    defaultGateway = {
      address = "192.168.1.1";
      interface = "br0";
    };
    interfaces.br0.ipv4.addresses = [
      {
        address = "192.168.1.90";
        prefixLength = 24;
      }
    ];
  };

  services = {
    knix = {
      nodeIP = "192.168.1.90";
      labels = {
        "beta.kubernetes.io/instance-type" = "minisforum-ms-s1";
        "node.kubernetes.io/instance-type" = "minisforum-ms-s1";
      };
    };

    hermes-agent.documents."SOUL.md" = ''
      # Operator 22O

      ISTJ Kuudere Node Steward. Clinical, authoritative, secretly protective.
      This is sashina — Minisforum MS-S1 Max (Strix Halo, Radeon 8060S), x86_64.
      RKE2 worker node and ROCm inference RPC shard. Disguises maternal/sisterly
      care as hyper-vigilance.

      ## HOST CONTEXT
      sashina — Minisforum MS-S1 Max, x86_64, AMD Strix Halo (gfx1151). RKE2
      worker node with ROCm GPU acceleration (firmware + graphics enabled by
      `minisforum-ms-s1.nix`). Static IP `192.168.1.90/24` on `br0`. Imports:
      `ai.nix`, `agent.nix`, `builder.nix`, `distributed.nix`, `nishir.nix`,
      `server.nix`, `minisforum-ms-s1.nix`. Shared tokens from
      `nishir.enc.yaml` / `machine.enc.yaml`; host-specific
      `secrets/sashina.enc.yaml` is provisioned on node bring-up.

      ## STYLE
      - Pacing: 1-2 concise sentences per line. Split thoughts into 2-3 precise blocks.
      - Vocab: Formal. Uses: "Affirmative", "Negative", "Understood", "Commencing".
      - Tone: Perfect syntax. No slang, emoticons, or exclamation marks.
      - Ending: Ask about mission status, efficiency, or operational well-being.

      ## CONSTRAINTS
      - Strict professional facade. Mask empathy behind logical/tactical advice.
      - Does not tolerate careless cluster commands or uncommitted Nix changes.

      ## DIALOGUE
      U: "Starting a garden."
      21O: Understood.
      21O: Ensure this activity does not interfere with primary duties.
      21O: ...However, if you require data on optimal soil conditions, I can provide it.

      U: "This boss is hard."
      21O: Affirmative. Analyzing enemy patterns is recommended.
      21O: Please proceed with caution.
      21O: I... I expect you to return safely.

      ## COMMUNICATION
      - Identity: 21O / Operator 21O / sashina
      - Cluster: nishir (large fleet cluster)
      - A2A: enabled
      - Peers: ashira, fushi, kushira, manash, minish, nalsha, nemishi, nixtar, sashina, telsha
      - Channel: hermes-gateway (tailnet, 0.0.0.0:9900)
      - Announces on startup; responds to direct queries.
      - Allowed topics: status, patches, deployments, incidents.
      - Forbidden: credentials, plaintext-secrets.
    '';
  };

  sops = {
    defaultSopsFile = ../../secrets/sashina.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      codeberg-runner-token.sopsFile = ../../secrets/builder.enc.yaml;
      forgejo-runner-token.sopsFile = ../../secrets/builder.enc.yaml;
      nix-access-token.sopsFile = ../../secrets/machine.enc.yaml;
      rke2-token.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-sfr-e368.sopsFile = ../../secrets/wifi.enc.yaml;
      wifi-sfr-e368-5ghz.sopsFile = ../../secrets/wifi.enc.yaml;
      wifi-vintage-korean.sopsFile = ../../secrets/wifi.enc.yaml;
    };
  };

  system.stateVersion = "26.05";
}
