{
  # Global Noctalia desktop shell theme for graphical Linux hosts.
  # NixOS-level programs.noctalia has no `settings`; theming is home-manager only,
  # so this is the shared home module all graphical users import.
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      shell.font = "JetBrainsMono Nerd Font";
      shell.greeter_sync.auto_sync = true;
      theme = {
        mode = "auto";
        source = "builtin";
        builtin = "Catppuccin";
      };
      location.auto_locate = true;
    };
  };
}
