{ pkgs, ... }:

{
  home.packages = [ pkgs.gh-stack ];

  programs.gh.extensions = with pkgs; [ gh-stack ];
}
