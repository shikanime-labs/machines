# GNOME session alternative (selectable at the greeter) plus the desktop
# services the Niri session leans on: keyring, GVfs, portals companions.
{
  services = {
    # GNOME desktop session — selectable at the greetd greeter
    # as an alternative to Niri. The .desktop file lands in
    # wayland-sessions and noctalia-greeter picks it up.
    desktopManager.gnome.enable = true;

    # Secret Service daemon so Thunderbird's login manager stores credentials
    # encrypted (Niri ships no keyring today).
    gnome = {
      gnome-keyring.enable = true;
      gnome-online-accounts.enable = true;
      gnome-software.enable = true;
      sushi.enable = true;
    };

    # GVfs: trash, removable-media mount, and network shares for nautilus.
    gvfs.enable = true;
  };
}
