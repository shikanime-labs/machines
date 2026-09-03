{ pkgs, ... }:

{
  boot = {
    binfmt.emulatedSystems = [ "aarch64-linux" ];

    # Strix Halo has no dedicated VRAM: the iGPU carves its working set out of
    # the 128GB unified LPDDR5X via GTT. The defaults cap GTT at roughly half
    # of RAM, which is not enough to keep a large model resident. 96GiB GTT
    # (gttsize is MiB) with a matching TTM page limit (96GiB / 4KiB pages).
    kernelParams = [
      "amdgpu.gttsize=98304"
      "ttm.pages_limit=25165824"
    ];

    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "xfs";
            mountpoint = "/";
          };
        };
      };
    };
  };

  # Radeon 8060S (gfx1151) needs firmware so ROCm compute and VAAPI reach
  # /dev/dri/renderD128. Userspace graphics libs + amdgpu initrd come from
  # nixos-hardware's common-gpu-amd.
  hardware.enableRedistributableFirmware = true;

  services.fstrim.enable = true;

  networking = {
    useNetworkd = true;

    # balance-alb (mode 6): aggregates both 10G NICs without switch-side LACP,
    # same reason as the Beelinks — the NETGEAR MS308 is unmanaged.
    # ponytail: mode 6 is unverified at 10G; drop bond0 and bridge enp1s0
    # directly if per-flow throughput regresses.
    bonds.bond0 = {
      # Realtek RTL8127. Names assumed to match the Beelink enumeration —
      # confirm with `ip -br link` on first boot before install.
      interfaces = [
        "enp1s0"
        "enp2s0"
      ];
      driverOptions = {
        mode = "balance-alb";
        miimon = "100";
      };
    };

    bridges.br0.interfaces = [ "bond0" ];
  };

  # NIC performance tuning: hardware offloads + RPS for both RTL8127 ports.
  systemd.services.network-nic-performance = {
    after = [ "network-online.target" ];
    description = "Enable NIC hardware offloads and RPS";
    script = ''
      for iface in enp1s0 enp2s0; do
        ip link show "$iface" >/dev/null 2>&1 || continue
        ${pkgs.ethtool}/bin/ethtool -K "$iface" rx-udp-gro-forwarding on rx-gro-list off
        ${pkgs.ethtool}/bin/ethtool -K "$iface" tso on gso on sg on tx on rx on 2>/dev/null || true
        for rxq in /sys/class/net/"$iface"/queues/rx-*; do
          echo ffff > "$rxq"/rps_cpus 2>/dev/null || true
        done
      done
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "5s";
    };
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
  };
}
