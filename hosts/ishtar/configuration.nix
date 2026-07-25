{ lib, ... }:

{
  imports = [
    ../../modules/nixos/razer-blade.nix
    ../../modules/nixos/agent.nix
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

  networking.hostName = "ishtar";

  # home-manager.users.shika.imports = [
  #   ./users/shika/home-configuration.nix
  # ];

  sops = {
    age = {
      generateKey = true;
      keyFile = "/var/lib/sops-nix/key.txt";
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
    defaultSopsFile = ../../secrets/ishtar.enc.yaml;
    defaultSopsFormat = "yaml";
    secrets = {
      wifi-sfr-e368.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-sfr-e368-5ghz.sopsFile = ../../secrets/nishir.enc.yaml;
      wifi-vintage-korean.sopsFile = ../../secrets/nishir.enc.yaml;
      # Shared cluster join token (R8). restartUnits inherited from agent.nix
      # (rke2-agent.service); only the sops file needs declaring here.
      rke2-token = {
        sopsFile = ../../secrets/nishir.enc.yaml;
      };
    };
  };

  # RKE2 agent — standby worker. role/enable/token/longhorn/canal come from
  # agent.nix (node.nix); only the laptop-specific knobs diverge and must
  # override the module defaults (mkForce). Longhorn stays enabled fleet-wide:
  # the worker-wedge premise is unfounded (minish/nemishi/fushi run it and the
  # PR's own integration test asserts it).
  services.knix = {
    serverAddr = lib.mkForce "https://nishir.taila659a.ts.net:9345"; # tailnet leader — ishtar roams
    interface = lib.mkForce "tailscale0";                            # laptop has no br0
    multus.enable = lib.mkForce false;                               # no 2nd NIC on a workstation
    # ishtar tailnet IP; re-sync after Tailscale machine-key rotation:
    #   tailscale ip -4 | head -1
    # ponytail: hardcoded tailnet IP, goes stale on key re-auth
    nodeIP = "100.85.127.78";
    labels = {
      "beta.kubernetes.io/instance-type" = "razer-blade-17";
      "node.kubernetes.io/instance-type" = "razer-blade-17";
    };
    # Standby node: tainted so nothing schedules unless explicitly tolerated.
    # ponytail: NoSchedule; drop the taint if ishtar should run general workloads.
    extraConfig."node-taint" = "ishtar.shikanime-labs/node-purpose=workstation:NoSchedule";
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
