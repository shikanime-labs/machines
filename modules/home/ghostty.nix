{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.isLinux then pkgs.ghostty else pkgs.ghostty-bin;
    settings = {
      theme = mkForce (
        if pkgs.stdenv.isLinux then "noctalia" else "dark:catppuccin-frappe,light:catppuccin-latte"
      );
      command = "${getExe pkgs.zsh} --login -c ${getExe pkgs.nushell}";
    };
    systemd.enable = pkgs.stdenv.isLinux;
  };

  xdg.configFile."ghostty/themes/catppuccin-frappe" = mkIf (!pkgs.stdenv.isLinux) {
    source = "${config.catppuccin.sources.ghostty}/catppuccin-frappe.conf";
  };
}
