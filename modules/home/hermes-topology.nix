# Fleet A2A topology and the shared hermes-agent helper set: peer name
# forms, A2A agent attrsets, sops secret declarations, and env template
# lines. Pure functions of lib and the host name — the sops plane
# (config placeholder lookup, owner/group) stays at the call site.
{ lib }:

with lib;

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

  mkA2aTokenSecretName = peer: "hermes-agent-a2a-token-${peer}";
  mkApiServerKeyName = peer: "hermes-agent-api-server-key-${peer}";

  mkA2aAgents =
    peers:
    listToAttrs (
      map (
        peer:
        nameValuePair peer.name {
          inherit (peer) capabilities;
          url = peer.url or "http://${peer.name}.taila659a.ts.net:9900";
          auth = {
            type = "bearer";
            token = "\${env:A2A_OWN_TOKEN}";
          };
        }
      ) peers
    );

  mkA2aPeerTokens =
    placeholder: peers:
    concatStringsSep "," (
      map (peer: "${peer.name}:${placeholder."hermes-agent-a2a-token-${peer.name}"}") peers
    );

  mkA2aTrustedPeers = peers: concatStringsSep "," (map (p: p.name) peers);

  mkBotPeers =
    peers:
    listToAttrs (
      map (peer: nameValuePair peer.name { url = "http://${peer.name}.taila659a.ts.net:8642"; }) peers
    );

  mkPeerKeyEnvs =
    placeholder: peers:
    concatStringsSep "\n" (
      map (
        peer:
        "HERMES_PEER_${toUpper peer.name}_KEY=${placeholder."hermes-agent-api-server-key-${peer.name}"}"
      ) peers
    );

  mkA2aTokenSecrets =
    attrs: peers: listToAttrs (map (peer: nameValuePair (mkA2aTokenSecretName peer.name) attrs) peers);

  mkPeerApiServerKeySecrets =
    attrs: peers: listToAttrs (map (peer: nameValuePair (mkApiServerKeyName peer.name) attrs) peers);

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

  inherit
    mkA2aTokenSecretName
    mkApiServerKeyName
    mkA2aAgents
    mkA2aPeerTokens
    mkA2aTrustedPeers
    mkBotPeers
    mkPeerKeyEnvs
    mkA2aTokenSecrets
    mkPeerApiServerKeySecrets
    ;
}
