# Omakase graphical desktop: everything a shikanime graphical session needs,
# in one import (omarchy-style). Apps: fuzzel launcher, Ghostty terminal (home),
# Nautilus, screenshot suite, media + brightness control, Bitwarden, Element.
# Session: Niri + Noctalia shell, greetd + Noctalia greeter, portals, polkit.
# Hardware: GPU + radios are host concerns; see ../hardware/.
{
  imports = [
    ./desktop.nix
    ./gaming.nix
    ./login.nix
    ./gnome-services.nix
    ./obs.nix
    ./polkit.nix
    ./steam.nix
  ];
}
