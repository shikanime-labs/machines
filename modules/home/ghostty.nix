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
    package = if pkgs.stdenv.hostPlatform.isLinux then pkgs.ghostty else pkgs.ghostty-bin;
    settings = {
      theme = mkForce "dark:catppuccin-frappe,light:catppuccin-latte";
      command = "${getExe pkgs.zsh} --login -c ${getExe pkgs.nushell}";
    };
    systemd.enable = pkgs.stdenv.hostPlatform.isLinux;
  };

  xdg.configFile."ghostty/themes/catppuccin-frappe" = {
    source = "${config.catppuccin.sources.ghostty}/catppuccin-frappe.conf";
  };
}
