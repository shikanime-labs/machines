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
    configPath = "${config.xdg.configHome}/starship/starship.toml";
    settings = {
      directory = {
        truncation_length = 4;
        style = "bold lavender";
      };
      git_branch.style = "bold mauve";
      palette = mkIf pkgs.stdenv.hostPlatform.isLinux (mkForce "catppuccin_latte");
    }
    // settings;
  };
}
