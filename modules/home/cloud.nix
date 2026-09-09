{ pkgs, ... }:

{
  imports = [
    ./krew.nix
  ];

  catppuccin.k9s.enable = false;

  home.packages = with pkgs; [
    fluxcd
    stern
  ];

  programs = {
    k9s = {
      enable = true;
      settings.k9s.ui.skin = "transparent";

      plugins = {
        logs = {
          shortCut = "Ctrl-L";
          description = "Tail pod logs with stern";
          scopes = [ "po" ];
          command = "stern";
          background = false;
          args = [
            "$NAME"
            "-n"
            "$NAMESPACE"
            "--context"
            "$CONTEXT"
          ];
        };

        flux-reconcile = {
          shortCut = "Ctrl-R";
          description = "Reconcile Flux Kustomization";
          scopes = [
            "ks"
            "kustomizations"
          ];
          command = "flux";
          background = true;
          args = [
            "reconcile"
            "kustomization"
            "$NAME"
            "-n"
            "$NAMESPACE"
            "--context"
            "$CONTEXT"
          ];
        };

        flux-suspend = {
          shortCut = "Ctrl-S";
          description = "Suspend Flux Kustomization";
          scopes = [
            "ks"
            "kustomizations"
          ];
          command = "flux";
          background = false;
          confirm = true;
          args = [
            "suspend"
            "kustomization"
            "$NAME"
            "-n"
            "$NAMESPACE"
            "--context"
            "$CONTEXT"
          ];
        };

      };
    };

    ssh.settings."ssh.dev.azure.com" = {
      HostkeyAlgorithms = "+ssh-rsa";
      PubkeyAcceptedKeyTypes = "+ssh-rsa";
    };
  };

  xdg.configFile."containers/policy.json".source =
    let
      format = pkgs.formats.json { };
    in
    format.generate "policy.json" {
      default = [
        { type = "insecureAcceptAnything"; }
      ];
      transports.docker-daemon = {
        "" = [ { type = "insecureAcceptAnything"; } ];
      };
    };
}
