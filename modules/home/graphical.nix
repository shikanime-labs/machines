{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bitwarden-desktop
    davinci-resolve
    dbeaver-bin
    discord
    element-desktop
    firefox
    google-chrome
    jellyfin-desktop
    obs-studio
    obsidian
    mattermost-desktop
    transmission
  ];
}
