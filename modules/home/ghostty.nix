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
      theme =
        if pkgs.stdenv.isLinux then
          mkForce "noctalia"
        else
          mkForce "dark:catppuccin-frappe,light:catppuccin-latte";
      command = "${getExe pkgs.zsh} --login -c ${getExe pkgs.nushell}";
    };
  };

  xdg.configFile."ghostty/themes/catppuccin-frappe".source = mkIf (
    !pkgs.stdenv.isLinux
  ) "${config.catppuccin.sources.ghostty}/catppuccin-frappe.conf";
}
