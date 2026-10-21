{ lib }:

let
  inherit (lib)
    concatStringsSep
    listToAttrs
    nameValuePair
    toUpper
    ;

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

  mkSelfExcludedPeers = { hostName, peers }: builtins.filter (p: p.name != hostName) peers;

  mkA2aAgent =
    {
      name,
      capabilities,
      url ? "http://${name}.taila659a.ts.net:9900",
    }:
    {
      inherit capabilities url;
      auth = {
        type = "bearer";
        token = "\${env:A2A_OWN_TOKEN}";
      };
    };

  mkA2aAgents = peers: listToAttrs (map (peer: nameValuePair peer.name (mkA2aAgent peer)) peers);

  mkA2aPeerToken =
    { placeholder, peer }: "${peer.name}:${placeholder."hermes-agent-a2a-token-${peer.name}"}";

  mkA2aTokenSecretName = peer: "hermes-agent-a2a-token-${peer}";

  mkPeerApiServerKeyName = peer: "hermes-agent-api-server-key-${peer}";

  mkA2aTrustedPeers = peers: concatStringsSep "," (map (p: p.name) peers);

  mkA2aPeerTokens =
    { placeholder, peers }:
    concatStringsSep "," (map (peer: mkA2aPeerToken { inherit placeholder peer; }) peers);

  mkBotPeers =
    peers:
    listToAttrs (
      map (peer: nameValuePair peer.name { url = "http://${peer.name}.taila659a.ts.net:8642"; }) peers
    );

  mkPeerKeyEnvs =
    { placeholder, peers }:
    concatStringsSep "\n" (
      map (
        peer: "HERMES_PEER_${toUpper peer.name}_KEY=${placeholder."${mkPeerApiServerKeyName peer.name}"}"
      ) peers
    );
  hubPeers = [
    {
      name = "automata";
      capabilities = [
        "command"
        "workstation"
      ];
      url = "http://automata.taila659a.ts.net:9900";
    }
  ];

  a2aTopology =
    hostName:
    let
      self = p: p.name != hostName;
      clusterMesh = builtins.filter self clusterPeers;
      isClusterPeer = builtins.any (p: p.name == hostName) clusterPeers;
      isHub = builtins.any (p: p.name == hostName) hubPeers;
      hubUplink = if isHub then builtins.filter self hubPeers else hubPeers;
      targets =
        if isClusterPeer then
          clusterMesh ++ hubUplink
        else if isHub then
          clusterPeers ++ hubUplink
        else
          builtins.filter self hubPeers;
      trusted = targets ++ lib.optionals isHub (builtins.filter self workstationPeers);
    in
    {
      inherit targets trusted;
    };
in
{
  inherit
    clusterPeers
    workstationPeers
    mkSelfExcludedPeers
    mkA2aAgents
    mkA2aTokenSecretName
    mkPeerApiServerKeyName
    mkA2aTrustedPeers
    mkA2aPeerTokens
    mkBotPeers
    mkPeerKeyEnvs
    ;
  peers = clusterPeers ++ workstationPeers;
  inherit hubPeers a2aTopology;

  mkA2aTokenSecrets =
    { sopsFile, peers }:
    listToAttrs (
      map (peer: nameValuePair (mkA2aTokenSecretName peer.name) { inherit sopsFile; }) peers
    );

  mkPeerApiServerKeySecrets =
    { sopsFile, peers }:
    listToAttrs (
      map (peer: nameValuePair (mkPeerApiServerKeyName peer.name) { inherit sopsFile; }) peers
    );
}
