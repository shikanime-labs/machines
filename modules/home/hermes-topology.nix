# Fleet A2A topology, shared between the NixOS-side sops templates and the
# home-manager service settings. Pure function of the host name.
{ lib }:

let
  clusterPeers = [
    {
      name = "ashira";
      capabilities = [
        "build"
        "build-x86"
        "k8s-follower"
      ];
    }
    {
      name = "fushi";
      capabilities = [
        "build"
        "build-arm"
        "k8s-node"
      ];
    }
    {
      name = "kushira";
      capabilities = [
        "build-x86"
        "k8s-node"
      ];
    }
    {
      name = "manash";
      capabilities = [
        "build"
        "build-x86"
        "k8s-leader"
      ];
    }
    {
      name = "minish";
      capabilities = [
        "build"
        "build-arm"
        "k8s-node"
      ];
    }
    {
      name = "nalsha";
      capabilities = [
        "build"
        "build-x86"
        "k8s-follower"
      ];
    }
    {
      name = "nemishi";
      capabilities = [
        "build"
        "build-arm"
        "k8s-node"
      ];
    }
    {
      name = "nishir";
      capabilities = [
        "build-x86"
        "k8s-leader"
      ];
    }
    {
      name = "sashina";
      capabilities = [
        "build-x86"
        "k8s-node"
      ];
    }
  ];

  workstationPeers = [
    {
      name = "automata";
      capabilities = [
        "command"
        "workstation"
      ];
    }
    {
      name = "nixtar";
      capabilities = [
        "graphical"
        "media"
        "nvidia"
        "k8s-leader"
      ];
    }
    {
      name = "telsha";
      capabilities = [
        "command"
        "workstation"
        "darwin"
      ];
    }
  ];

  hubPeers = [
    {
      name = "automata";
      capabilities = [
        "command"
        "workstation"
      ];
      url = "https://a2a.automata.i.shikanime.studio";
    }
  ];

  mkSelfExcludedPeers = hostname: peers: builtins.filter (p: p.name != hostname) peers;
in
{
  inherit clusterPeers workstationPeers hubPeers;
  peers = clusterPeers ++ workstationPeers;
  targets =
    hostname:
    let
      isClusterPeer = builtins.any (p: p.name == hostname) clusterPeers;
      isHub = builtins.any (p: p.name == hostname) hubPeers;
      hubUplink = if isHub then mkSelfExcludedPeers hostname hubPeers else hubPeers;
      a2aTargets =
        if isClusterPeer then
          (mkSelfExcludedPeers hostname clusterPeers) ++ hubUplink
        else if isHub then
          clusterPeers ++ hubUplink
        else
          mkSelfExcludedPeers hostname hubPeers;
      hubTrust = lib.optionals isHub (mkSelfExcludedPeers hostname workstationPeers);
    in
    {
      inherit a2aTargets hubTrust;
      otherPeers = mkSelfExcludedPeers hostname (clusterPeers ++ workstationPeers);
    };
}
