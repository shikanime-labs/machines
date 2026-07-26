{ config, pkgs, ... }:

{
  home.packages = with pkgs; [ krew ];

  home = {
    # Make krew plugin discoverable for kubectl
    sessionPath = [ "${config.home.homeDirectory}/.local/share/krew/bin" ];

    # Plugins installation location
    sessionVariables.KREW_ROOT = "${config.home.homeDirectory}/.local/share/krew";
  };
}
