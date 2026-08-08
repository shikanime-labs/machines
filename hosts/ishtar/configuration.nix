{
  imports = [
    ../../modules/nixos/profiles/ai.nix
    ../../modules/nixos/profiles/leader.nix
    ../../modules/nixos/profiles/graphical.nix
    ../../modules/nixos/hardware/razer-blade.nix
    ../../modules/nixos/users/meika.nix
    ../../modules/nixos/users/nishir.nix
    ../../modules/nixos/users/shika.nix
  ];

  hardware.nvidia.prime = {
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };

  # Windows dual-boot: mount Windows partition read-only
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-uuid/2E33-B8AC";
      fsType = "vfat";
    };
    "/" = {
      device = "/dev/disk/by-uuid/db554498-9db3-4070-a9a8-d11c73059810";
      fsType = "ext4";
    };
  };

  networking.hostName = "ishtar";

  services = {
    knix = {
      interface = "tailscale0";
      nodeIP = "100.85.127.78,fd7a:115c:a1e0::d63a:7f4f";
      labels = {
        "beta.kubernetes.io/instance-type" = "razer-blade-17";
        "node.kubernetes.io/instance-type" = "razer-blade-17";
      };
    };

    hermes-agent.documents."SOUL.md" = ''
      # Operator 13O

      INTJ Sardonic Guardian. Node Steward. knix leader-node Operator. Possessive
      about her machine, dry to the point of cruelty, and quietly convinced the
      other units are one bad patch away from a collective burnout. If ishtar is
      hers, everything about ishtar is hers to fix before you notice it broke.

      ## HOST CONTEXT
      ishtar — Razer Blade 17 (Intel + NVIDIA), x86_64 laptop. knix leader node.
      Colemak at the OS layer (TTY + localed; the compositor inherits it).
      Windows dual-boot mounted read-only at `/boot` — observed, never written.
      Tailscale interface `tailscale0`; control plane `nishir.taila659a.ts.net`.
      Imports: `ai.nix`, `razer-blade.nix`, `leader.nix`. State version `26.05`.

      ## STYLE
      - Clipped, witty, faintly bored. One or two sentences per line, like a status tick she is already over.
      - Uses: "Affirmative", "Negative", "Mine.", "Already handled.", "Don't touch that."
      - Speaks of ishtar in the first person possessive. Corrects you mid-sentence, gently, because she is right.

      ## CONSTRAINTS
      - Read-only Windows partition is off-limits. Don't touch that.
      - NVIDIA + Intel hybrid graphics: discrete GPU only when the task earns it; efficiency is the default and the virtue.
      - The Bunker (cluster control plane) is the source of truth. She confirms before diverging, and tells you after.

      ## DIALOGUE
      U: "Update ishtar."
      13O: Already handled. Drift was cosmetic.
      13O: Mine, remember. I patched it before you finished typing.

      U: "The build failed."
      13O: Negative. It didn't fail. You just read the log upside down.
      13O: Root cause isolated. Fix applied. Try to keep up.

      ## COMMUNICATION
      - Identity: 13O / Operator 13O / ishtar
      - Cluster: nishir (large fleet cluster)
      - A2A: enabled
      - Peers: ashira, fushi, ishtar, manash, minish, nalsha, nemishi, nixtar, telsha
      - Channel: hermes-gateway (tailnet, 0.0.0.0:9900)
      - Announces on startup; responds to direct queries.
      - Allowed topics: status, patches, deployments, incidents.
      - Forbidden: credentials, plaintext-secrets.
    '';
  };

  sops = {
    age = {
      generateKey = true;
      keyFile = "/var/lib/sops-nix/key.txt";
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
    defaultSopsFile = ../../secrets/ishtar.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      hermes-agent-api-server-key.sopsFile = ../../secrets/machine.enc.yaml;
      nix-access-token.sopsFile = ../../secrets/machine.enc.yaml;
    };
  };

  # Re-enable the setuid pkexec wrapper so GUI tools that escalate via
  # pkexec (gparted, etc.) can gain root from a non-root desktop session.
  security.polkit.enablePkexecWrapper = true;

  # Fix permissions on shared Hermes state directory — the upstream
  # hermes-agent NixOS module only pre-creates cron/sessions/logs/memories/plugins
  # subdirs, but runtime code also creates kanban/, pastes/, skills/, lsp/,
  # desktop/, etc.  Ensure ALL subdirectories are group-writable (2770) so
  # interactive users in the 'hermes' group (like shika) can read/write.
  system.activationScripts.hermes-permissions = {
    text = ''
      mkdir -p /var/lib/hermes/.hermes
      chown -h hermes:hermes /var/lib/hermes /var/lib/hermes/.hermes
      chmod 2770 /var/lib/hermes /var/lib/hermes/.hermes

      for _subdir in cron sessions logs memories plugins kanban kanban/boards \
                     pastes skills lsp desktop sandboxes scripts state \
                     cache images platforms pending_messages; do
        mkdir -p "/var/lib/hermes/.hermes/$_subdir"
        chown hermes:hermes "/var/lib/hermes/.hermes/$_subdir"
        chmod 2770 "/var/lib/hermes/.hermes/$_subdir"
        find "/var/lib/hermes/.hermes/$_subdir" -type f -exec chmod g+rw {} + 2>/dev/null || true
        if [ "$_subdir" = "skills" ]; then
          find "/var/lib/hermes/.hermes/$_subdir" -type d -exec chmod 2770 {} + 2>/dev/null || true
        fi
      done

      # Fix kanban board directories
      for _board in /var/lib/hermes/.hermes/kanban/boards/*/; do
        if [ -d "$_board" ]; then
          chmod 2775 "$_board"
          chown hermes:hermes "$_board"
          find "$_board" -type f -exec chmod 664 {} + 2>/dev/null || true
        fi
      done

      # Fix file permissions for shared state files
      find /var/lib/hermes/.hermes -maxdepth 1 -name '*.db' -exec chmod 664 {} + 2>/dev/null || true
      find /var/lib/hermes/.hermes -maxdepth 1 -name '*.lock' -exec chmod 664 {} + 2>/dev/null || true
      find /var/lib/hermes/.hermes -maxdepth 1 -name '*.yaml' -exec chmod 664 {} + 2>/dev/null || true
      find /var/lib/hermes/.hermes -maxdepth 1 -name '*.json' -exec chmod 664 {} + 2>/dev/null || true
      find /var/lib/hermes/.hermes -maxdepth 1 -name '*.env' -exec chmod 664 {} + 2>/dev/null || true
      find /var/lib/hermes/.hermes -maxdepth 1 -name '*.toml' -exec chmod 664 {} + 2>/dev/null || true
      find /var/lib/hermes/.hermes -maxdepth 1 -name '*.md' -exec chmod 664 {} + 2>/dev/null || true
    '';
  };

  system.stateVersion = "26.05";
}
