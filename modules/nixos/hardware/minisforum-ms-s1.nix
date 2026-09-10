{ pkgs, config, ... }:

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

    kernelModules = [ "thunderbolt-net" ];

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

  hardware.enableRedistributableFirmware = true;

  networking = {
    bonds.bond0 = {
      # Realtek RTL8127. Names assumed to match the Beelink enumeration —
      # confirm with `ip -br link` on first boot before install.
      interfaces = [
        "enp97s0"
        "enp98s0"
      ];
      driverOptions = {
        mode = "balance-alb";
        miimon = "100";
      };
    };

    bridges.br0.interfaces = [ "bond0" ];

    # balance-alb (mode 6): aggregates both 10G NICs without switch-side LACP,
    # same reason as the Beelinks — the NETGEAR MS308 is unmanaged.
    # ponytail: mode 6 is unverified at 10G; drop bond0 and bridge enp1s0
    # directly if per-flow throughput regresses.
    useNetworkd = true;
  };

  services.fstrim.enable = true;

  systemd = {
    # Direct USB4 peer link (kushira <-> sashina) carrying the llama.cpp
    # ggml RPC traffic (~8 us vs ~65 us over the 10G bond). Static /29 —
    # no DHCP server exists on a bare cable. sashina .1, kushira .2;
    # 10.66.0.3-.5 are pinned for the Multus pod attachments (manifests
    # apps/llama-cpp*). MTU 65522 is the thunderbolt-net driver max
    # (TBNET_MAX_MTU - ETH_HLEN). The address block is keyed by hostName
    # so this single unit serves both peers; networkd binds the first
    # matching .network exclusively, so hosts/sashina must not add a
    # second tb-matching unit.
    network.networks."40-thunderbolt" = {
      matchConfig.Driver = "thunderbolt-net";
      linkConfig = {
        MTUBytes = 65522;
        RequiredForOnline = "no";
      };
      networkConfig.LinkLocalAddressing = "no";
      address = [
        (if config.networking.hostName == "sashina" then "10.66.0.1/29" else "10.66.0.2/29")
      ];
    };

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
