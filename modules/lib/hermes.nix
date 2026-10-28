{ lib }:

with lib;

rec {
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
      map (peer: "${peer.name}:${placeholder."${mkA2aTokenSecretName peer.name}"}") peers
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
        peer: "HERMES_PEER_${toUpper peer.name}_KEY=${placeholder."${mkApiServerKeyName peer.name}"}"
      ) peers
    );

  mkA2aTokenSecrets =
    attrs: peers: listToAttrs (map (peer: nameValuePair (mkA2aTokenSecretName peer.name) attrs) peers);

  mkPeerApiServerKeySecrets =
    attrs: peers: listToAttrs (map (peer: nameValuePair (mkApiServerKeyName peer.name) attrs) peers);
}
