{ pkgs, ... }:

{
  boot = {
    binfmt.emulatedSystems = [ "aarch64-linux" ];

    # Strix Halo has no dedicated VRAM: the iGPU carves its working set out of
    # the 128GB unified LPDDR5X via GTT. The defaults cap GTT at roughly half
    # of RAM, which is not enough to keep a large model resident. Give the
    # iGPU the full 128GiB ceiling (gttsize is MiB) with a matching TTM page
    # limit (128GiB / 4KiB pages) — GTT is demand-paged, so this is an upper
    # bound, not a reservation; pages commit only when the GPU touches them.
    kernelParams = [
      "amdgpu.gttsize=131072"
      "ttm.pages_limit=33554432"
    ];

    kernel.sysctl = {
      "net.core.busy_poll" = 50;
      "net.core.busy_read" = 50;
    };

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

  # OpenCL via the ROCm runtime ICD; firmware so compute reaches
  # /dev/dri/renderD128 (Mesa GL/Vulkan userspace comes from nixos-hardware's
  # common-gpu-amd).
  hardware = {
    amdgpu.opencl.enable = true;
    enableRedistributableFirmware = true;
  };

  # GPU observability and compute-verification tooling.
  environment.systemPackages = with pkgs; [
    rocmPackages.rocminfo
    rocmPackages.rocm-smi
  ];

  networking = {
    # Realtek RTL8127 ports, one bridge each.
    bridges = {
      # br0: LAN uplink.
      br0.interfaces = [ "enp97s0" ];
      # br1: direct node-to-node peer link to kushira for llama.cpp RPC
      # (10.66.0.0/29, pods .3-.5); covered by the profile's br+ glob.
      br1.interfaces = [ "enp98s0" ];
    };

    useNetworkd = true;
  };

  services.fstrim.enable = true;

  systemd = {
    # NIC performance tuning: hardware offloads + RPS for both RTL8127 ports.
    services.network-nic-performance = {
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
  };
}
