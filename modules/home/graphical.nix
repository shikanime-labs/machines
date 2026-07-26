{
  # Global Noctalia desktop shell theme for graphical Linux hosts.
  # NixOS-level programs.noctalia has no `settings`; theming is home-manager only,
  # so this is the shared home module all graphical users import.
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      shell.font = "Fira Code";
      shell.polkit_agent = true;
      shell.greeter_sync.auto_sync = true;
      theme = {
        mode = "auto";
        source = "builtin";
        builtin = "Catppuccin";
      };
      location.auto_locate = true;
      # Load the Bitwarden vault-lookup plugin from this repo (path source).
      # Location points at the official source dir, so the plugin id
      # "shikanime/bitwarden" resolves to plugins/official/bitwarden/plugin.toml.
      plugins = {
        sources = [
          {
            kind = "path";
            name = "machines-local";
            location = "plugins/official";
            enabled = true;
          }
        ];
        enabled = [ "shikanime/bitwarden" ];
      };
    };
  };
}
