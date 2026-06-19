{ lib, ... }:

with lib;
{
  config = mkMerge [
    {
      knix.addons = {
        flux = {
          enable = mkDefault true;
          instance.extraConfig.instance.sync = mkDefault {
            interval = "1m";
            kind = "GitRepository";
            path = "clusters/nishir/overlays/tailnet";
            pullSecret = "";
            ref = "refs/heads/main";
            url = "https://github.com/shikanime/manifests.git";
          };
        };

        longhorn.extraConfig.ingress = mkDefault {
          annotations."tailscale.com/tags" = "tag:web";
          enabled = true;
          host = "nishir-longhorn";
          ingressClassName = "tailscale";
        };
      };
    }
  ];
}
