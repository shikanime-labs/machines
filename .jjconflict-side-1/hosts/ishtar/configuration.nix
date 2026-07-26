{
  imports = [
    ../../modules/nixos/profiles/ai.nix
    ../../modules/nixos/profiles/leader.nix
    ../../modules/nixos/profiles/graphical.nix
    ../../modules/nixos/hardware/razer-blade.nix
    ../../modules/nixos/users/nishir.nix
  ];

  # Colemak at the OS level (TTY + localed -> niri reads it).
  colemak.enable = true;

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
    '';
  };

  networking.hostName = "ishtar";

  home-manager.users.shika.imports = [
    ../../modules/nixos/users/shika.nix
  ];

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

  users.users.shika = {
    extraGroups = [
      "wheel"
      "plugdev"
    ];
    home = "/home/shika";
    initialHashedPassword = "$y$j9T$3nIVNUGT/i3/bS3kiaDC7.$KgHv3Ld.O989KuqPTkJlSHq4Uq47eLVES6mL2Vlo324";
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH+tp1Xfz7NomHCZuDPlfj3XW5hm9t0TiCyEeudRraoe"
    ];
  };

  system.stateVersion = "26.05";
}
