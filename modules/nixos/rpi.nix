{ pkgs, ... }:

{
  boot.kernelParams = [
    # Older Raspberry Pi-class boards still need these cgroup knobs for RKE2.
    "cgroup_enable=cpuset"
    "cgroup_enable=memory"
    "cgroup_memory=1"
    # Disable USB runtime autosuspend; external SSD drops offline under load
    "usbcore.autosuspend=-1"
    # Bind SABRENT/JMicron enclosure to usb-storage, bypassing UASP
    "usb-storage.quirks=152d:a578:u"
  ];

  nixpkgs.overlays = [
    (_: super: {
      makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  networking = {
    useNetworkd = true;

    # Single NIC bridge — all traffic (flannel, SSH, Longhorn) on one wire.
    bridges.br0.interfaces = [ "end0" ];
  };

  # NIC performance tuning: hardware offloads + RPS for the USB3 GigE port.
  systemd.services.network-nic-performance = {
    after = [ "network-online.target" ];
    description = "Enable NIC hardware offloads and RPS";
    script = ''
      for iface in end0; do
        ip link show "$iface" >/dev/null 2>&1 || continue
        ${pkgs.ethtool}/bin/ethtool -K "$iface" rx-udp-gro-forwarding on rx-gro-list off
        ${pkgs.ethtool}/bin/ethtool -K "$iface" tso on gso on sg on tx on rx on 2>/dev/null || true
        for rxq in /sys/class/net/"$iface"/queues/rx-*; do
          echo f > "$rxq"/rps_cpus 2>/dev/null || true
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
