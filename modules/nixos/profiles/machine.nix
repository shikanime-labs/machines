{
  pkgs,
  lib,
  config,
  ...
}:

{
  imports = [ ./base.nix ];

  # Force glibc to prefer IPv4 over IPv6 for dual-stack destinations.
  networking.getaddrinfo.precedence = {
    "::1/128" = 50;
    "::/0" = 40;
    "2002::/16" = 30;
    "::/96" = 20;
    "::ffff:0:0/96" = 100;
  };

  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
      publish = {
        addresses = true;
        enable = true;
        workstation = true;
      };
    };

    fail2ban.enable = true;

    openssh = {
      enable = true;
      openFirewall = true;
    };

    tailscale = {
      enable = true;
      extraUpFlags = [
        "--accept-routes"
        "--ssh"
      ];
      openFirewall = true;
      useRoutingFeatures = "both";
    };

    # RAPL energy counters are root-only 0400 by default; node_exporter runs as
    # the node-exporter user and the rapl collector fails without read access.
    # Group + udev rule keep the counters readable without running as root.
    udev.extraRules = ''
      SUBSYSTEM=="powercap", RUN+="${pkgs.coreutils}/bin/chgrp rapl /sys/class/powercap/intel-rapl*"
      SUBSYSTEM=="powercap", RUN+="${pkgs.coreutils}/bin/chmod 0440 /sys/class/powercap/intel-rapl*"
    '';

    # Userspace hardware watchdog + system resource monitor
    watchdogd = {
      enable = true;
      settings = {
        meminfo.enabled = true;
        timeout = 120; # Increased from 15s to prevent premature reboots
      };
    };
  };

  systemd = {
    # XFS no longer panics on I/O errors: on USB-backed nodes a transient
    # enclosure I/O error was panicking the kernel and reboot-looping. Let XFS
    # remount read-only and ride out the hiccup instead.
    oomd.enable = true;

    tmpfiles.rules = [ "z /sys/class/powercap/intel-rapl* 0440 root rapl - -" ];
  };

  users = {
    groups.rapl = { };

    # Only define the user when the exporter exists: the key itself instantiates
    # the record, so an ungated stub trips the isSystemUser/group assertions.
    users.node-exporter = lib.mkIf config.services.prometheus.exporters.node.enable {
      extraGroups = [ "rapl" ];
    };
  };

  # zram swap so the kernel OOM-killer isn't the first responder on small nodes.
  # PSI is enabled by default on NixOS std kernel; that also lets systemd-oomd run.
  zramSwap.enable = true;
}
