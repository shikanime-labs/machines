{ pkgs, ... }:

{
  home.packages = [
    pkgs.fira-code
    pkgs.inriafonts
  ];

  fonts.fontconfig.enable = true;
}
