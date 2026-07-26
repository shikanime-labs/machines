{
  # Global Noctalia desktop shell theme for graphical Linux hosts.
  # NixOS-level programs.noctalia has no `settings`; theming is home-manager only,
  # so this is the shared home module all graphical users import.
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      location.auto_locate = true;
      shell = {
        font = "Fira Code";
        polkit_agent = true;
        greeter_sync.auto_sync = true;
      };
      theme = {
        mode = "auto";
        source = "builtin";
        builtin = "Catppuccin";
      };
    };
  };
}
