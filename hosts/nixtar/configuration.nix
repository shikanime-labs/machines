{
  imports = [
    ../../modules/nixos/profiles/ai.nix
    ../../modules/nixos/profiles/leader.nix
    ../../modules/nixos/profiles/graphical.nix
    ../../modules/nixos/hardware/razer-blade.nix
    ../../modules/nixos/users/meika.nix
    ../../modules/nixos/users/nishir.nix
    ../../modules/nixos/users/shika.nix
    ../../modules/nixos/users/operator-13o.nix
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

  networking.hostName = "nixtar";

  services = {
    knix = {
      interface = "tailscale0";
      nodeIP = "100.85.127.78,fd7a:115c:a1e0::d63a:7f4f";
      labels = {
        "beta.kubernetes.io/instance-type" = "razer-blade-17";
        "node.kubernetes.io/instance-type" = "razer-blade-17";
      };
    };

  };

  sops = {
    age = {
      generateKey = true;
      keyFile = "/var/lib/sops-nix/key.txt";
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
    defaultSopsFile = ../../secrets/nixtar.enc.yaml;
    defaultSopsFormat = "yaml";
  };

  # Re-enable the setuid pkexec wrapper so GUI tools that escalate via
  # pkexec (gparted, etc.) can gain root from a non-root desktop session.
  security.polkit.enablePkexecWrapper = true;

  # The openrazer module creates an `openrazer` group whose members come ONLY
  # from hardware.openrazer.users. Without shika listed, openrazer-daemon.service
  # exits 1 ("User is not a member of the openrazer group") and the user service
  # hits start-limit-hit at boot. Host-specific, so set it here rather than the
  # shared hardware module.
  hardware.openrazer.users = [ "shika" ];

  system.stateVersion = "26.05";
}
