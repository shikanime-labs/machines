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

        ks-toggle = {
          shortCut = "Shift-T";
          description = "Toggle Kustomization suspend";
          scopes = [
            "ks"
            "kustomizations"
          ];
          command = "bash";
          background = false;
          confirm = true;
          args = [
            "-c"
            ''
              suspended=$(kubectl --context $CONTEXT get kustomizations -n $NAMESPACE $NAME -o=custom-columns=TYPE:.spec.suspend | tail -1);
              verb=$([ $suspended = "true" ] && echo resume || echo suspend);
              flux $verb kustomization --context $CONTEXT -n $NAMESPACE $NAME | less -K
            ''
          ];
        };

        ks-reconcile = {
          shortCut = "Shift-R";
          description = "Reconcile Kustomization";
          scopes = [
            "ks"
            "kustomizations"
          ];
          command = "flux";
          background = false;
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

        hr-toggle = {
          shortCut = "Shift-T";
          description = "Toggle HelmRelease suspend";
          scopes = [ "helmreleases" ];
          command = "bash";
          background = false;
          confirm = true;
          args = [
            "-c"
            ''
              suspended=$(kubectl --context $CONTEXT get helmreleases -n $NAMESPACE $NAME -o=custom-columns=TYPE:.spec.suspend | tail -1);
              verb=$([ $suspended = "true" ] && echo resume || echo suspend);
              flux $verb helmrelease --context $CONTEXT -n $NAMESPACE $NAME | less -K
            ''
          ];
        };

        hr-reconcile = {
          shortCut = "Shift-R";
          description = "Reconcile HelmRelease";
          scopes = [ "helmreleases" ];
          command = "flux";
          background = false;
          args = [
            "reconcile"
            "helmrelease"
            "$NAME"
            "-n"
            "$NAMESPACE"
            "--context"
            "$CONTEXT"
          ];
        };

        trace = {
          shortCut = "Shift-Q";
          description = "Flux trace";
          scopes = [ "all" ];
          command = "bash";
          background = false;
          args = [
            "-c"
            ''
              if [ -n "$RESOURCE_GROUP" ]; then api_endpoint="/apis/$RESOURCE_GROUP/$RESOURCE_VERSION"; else api_endpoint="/api/$RESOURCE_VERSION"; fi;
              api_resource=$(kubectl get --raw "$api_endpoint" | jq -r ".resources[] | select(.name==\"$RESOURCE_NAME\")");
              kind=$(echo $api_resource | jq -r ".kind");
              namespace_arg=$(echo $api_resource | jq -r "if .namespaced == true then \"--namespace $NAMESPACE\" else \"\" end");
              [ -n "$RESOURCE_GROUP" ] && api_version=$RESOURCE_GROUP/;
              api_version=$api_version$RESOURCE_VERSION;
              flux trace --context $CONTEXT --kind $kind --api-version $api_version $namespace_arg $NAME |& less -K
            ''
          ];
        };

        suspended = {
          shortCut = "Shift-S";
          description = "List suspended Flux resources";
          scopes = [
            "ks"
            "hr"
            "kustomizations"
            "helmreleases"
          ];
          command = "bash";
          background = false;
          args = [
            "-c"
            ''
              for kind in kustomizations.kustomize.toolkit.fluxcd.io helmreleases.helm.toolkit.fluxcd.io; do
                kubectl get --context $CONTEXT --all-namespaces $kind -o json 2>/dev/null;
              done | jq -s -r 'map(.items[]?) | .[] | select(.spec.suspend==true) | [.kind,.metadata.namespace,.metadata.name] | @tsv' | less -K
            ''
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
