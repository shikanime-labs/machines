{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  settings = importTOML "${config.catppuccin.sources.starship}/latte.toml";
in
{
  programs.starship = {
    enable = true;
    settings = {
      directory = {
        truncation_length = 4;
        style = "bold lavender";
      };
      git_branch.style = "bold mauve";
      palette = mkForce (if pkgs.stdenv.isLinux then "catppuccin_latte" else "catppuccin_frappe");
    }
    // settings;
  };
}
