{
  # Global Noctalia desktop shell theme for graphical Linux hosts.
  # NixOS-level programs.noctalia has no `settings`; theming is home-manager only,
  # so this is the shared home module all graphical users import.
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      shell.font = "Fira Code";
      shell.greeter_sync.auto_sync = true;
      theme = {
        mode = "auto";
        source = "builtin";
        builtin = "Catppuccin";
      };
      location.auto_locate = true;

      # DDC/CI monitor brightness control via ddcutil (already in systemPackages).
      # Noctalia auto-detects the I2C bus per connected monitor; no manual bus address.
      brightness.enable_ddcutil = true;
    };
  };
}
