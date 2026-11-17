{ config, ... }:

{
  imports = [ ./machine.nix ];

  # Headless server auth: bring Tailscale up unattended with a node auth key.
  # Workstations intentionally do NOT import this profile — they fall back to a
  # human-run `tailscale up` at the console/GUI instead of an automated token.
  services.tailscale.authKeyFile = config.sops.secrets.tailscale-authkey.path;

  # Tailscale must not own the system resolver: accept-dns lets it push `~.`
  # onto tailscale0, so a slow MagicDNS path stalls node DNS — including
  # kubelet containerd pulls (fushi, 2026-11-16: ~20 min of image-pull
  # i/o timeouts on 127.0.0.53). Pin ts.net resolution on resolved instead:
  # the LAN resolver stays current for everything else, and only
  # *.taila659a.ts.net routes to 100.100.100.100.
  services.tailscale.extraUpFlags = [ "--accept-dns=false" ];
  services.resolved.settings = {
    Resolve = {
      DNS = [ "100.100.100.100" ];
      Domains = [ "~taila659a.ts.net" ];
    };
  };

  sops.secrets.tailscale-authkey.restartUnits = [ "tailscaled-autoconnect.service" ];
}
