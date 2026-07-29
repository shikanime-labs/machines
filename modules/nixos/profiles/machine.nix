{ pkgs, config, ... }:

{
  imports = [
    ./base.nix
  ];

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
      authKeyFile = config.sops.secrets.tailscale-authkey.path;
      enable = true;
      extraUpFlags = [
        "--accept-routes"
        "--ssh"
      ];
      openFirewall = true;
      useRoutingFeatures = "server";
    };

    # Userspace hardware watchdog + system resource monitor
    watchdogd = {
      enable = true;
      settings = {
        meminfo.enabled = true;
        timeout = 120; # Increased from 15s to prevent premature reboots
      };
    };
  };

  sops.secrets.tailscale-authkey.restartUnits = [ "tailscaled.service" ];

  # XFS no longer panics on I/O errors: on USB-backed nodes a transient
  # enclosure I/O error was panicking the kernel and reboot-looping. Let XFS
  # remount read-only and ride out the hiccup instead.
  systemd.oomd.enable = true;

  # zram swap so the kernel OOM-killer isn't the first responder on small nodes.
  # PSI is enabled by default on NixOS std kernel; that also lets systemd-oomd run.
  zramSwap.enable = true;

  environment.systemPackages = with pkgs; [
    syncthing
  ];

  environment.etc."syncthing/config.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <directory version="27">
      <gui enabled="true" tls="false" authentication="false" rawAddresses="true">
        <address>127.0.0.1:8384</address>
        <apikey></apikey>
      </gui>
      <options>
        <defaults>
          <listenAddresses>
            <listenAddress>tcp://0.0.0.0:22000</listenAddress>
          </listenAddresses>
        </defaults>
      </options>
    </directory>
  '';

  # Force glibc to prefer IPv4 over IPv6 for dual-stack destinations.
  networking.getaddrinfo.precedence = {
    "::1/128" = 50;
    "::/0" = 40;
    "2002::/16" = 30;
    "::/96" = 20;
    "::ffff:0:0/96" = 100;
  };
}
