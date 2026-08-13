{ config, ... }:

{
  imports = [
    ./machine.nix
  ];

  # Headless server auth: bring Tailscale up unattended with a node auth key.
  # Workstations intentionally do NOT import this profile — they fall back to a
  # human-run `tailscale up` at the console/GUI instead of an automated token.
  services.tailscale.authKeyFile = config.sops.secrets.tailscale-authkey.path;

  sops.secrets.tailscale-authkey.restartUnits = [ "tailscaled.service" ];
}
