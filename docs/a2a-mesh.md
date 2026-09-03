<!-- owner: shikanime | zone: internal | purpose: document the directional A2A agent mesh and its tailnet ACL backstop across the cluster↔workstation boundary -->

# A2A Agent Mesh

Directional mesh of Hermes agents across the Shikanime fleet, reachable over the
Tailscale tailnet (`*.taila659a.ts.net`). Each host runs a Hermes agent that
exposes an A2A server on `:9900` (and an api_server on `:8642`). Tailscale
`serve --https` terminates TLS at the funnel and forwards to the local agent;
peers dial `https://<host>.taila659a.ts.net:9900`.

## Topology

- **Peers** (`modules/nixos/profiles/ai.nix` `peers`, mirrored in the
  darwin-gated A2A block of `modules/home/workstation.nix` for telsha): ashira,
  fushi, manash, minish, nalsha, nemishi, nixtar, sashina, kushira, nishir,
  telsha.
- **Cluster peers** (NixOS): the ten `*.nixos`/k8s hosts.
- **Workstation peers**: nixtar, telsha (macOS darwin). catbox holds an issued
  a2a token (declared in `secrets/machine.enc.yaml`) but is not part of the
  `peers` list, so it is not dialed or trusted by the mesh.

## Directional rule (the boundary)

The mesh is **unidirectional at the cluster↔workstation boundary** (PR #1241):

- **Clusters** dial _and_ trust every other peer except self. They are the
  trusted core: `trusted = all peers \ self`, `outbound = all peers \ self`.
- **Workstations** (nixtar, telsha) dial _clusters plus other workstations_
  (outbound = all peers \ self) but **trust only other workstations**. A
  workstation never appears in a cluster's trusted set, and a cluster never
  accepts inbound from a workstation.

This keeps the control plane (clusters) authoritative while letting workstations
cooperate with each other (e.g. telsha ↔ nixtar) without either being able to
command a cluster.

## How it is enforced (two layers)

1. **App layer** — `modules/nixos/profiles/ai.nix` and the darwin-gated A2A
   block in `modules/home/workstation.nix` compute `trusted`/`outbound` from the
   peer lists via `mkSelfExcludedPeers` semantics. Auth uses per-peer bearer
   tokens (`A2A_OWN_TOKEN` + `A2A_PEER_TOKENS`) rendered from sops secrets
   (`hermes-agent-a2a-token-<peer>`).
2. **Network layer (backstop)** — the tailnet ACL (`tailnet/policy.hujson`)
   denies `tag:machine → tag:workstation :9900/:8642`. If a cluster were ever
   misconfigured to dial a workstation, the packet is dropped at the network
   layer. The ACL `tests[]` block asserts this so a future edit cannot widen
   access without the test job failing before apply.

Reachability therefore requires both layers to agree: workstation→cluster is
permitted by the ACL grant (`tag:automata → tag:automata :9900/:8642`) and by
the app-layer trusted/outbound sets.

## darwin enablement (telsha)

telsha runs Hermes via the Home Manager `services.hermes-agent` LaunchAgent
(nix-darwin has no `services.tailscale`, and Tailscale is the GUI app). The
darwin wiring lives in:

- `modules/home/workstation.nix` — the A2A settings, sops token templates, and
  peer-key env are folded into `services.hermes-agent` (and `sops.secrets`/
  `sops.templates`) under a `pkgs.stdenv.isDarwin` gate, with `hostName` fixed
  to `telsha` (the Home Manager config has no `networking.hostName`). This file
  is shared with the NixOS hosts, so the gate keeps the A2A surface darwin-only.
- `modules/darwin/profiles/workstation.nix` — the `launchd.daemons` oneshots
  that `tailscale up --advertise-tags=tag:automata,tag:workstation` and
  `tailscale serve --https=9900/8642` to localhost. No nix-darwin firewall
  opening is needed (the agent listens on localhost; Tailscale forwards the
  funnel).

## Operation

- **Add a peer**: append to `peers` in `modules/nixos/profiles/ai.nix` AND the
  darwin-gated A2A `a2aPeers` block in `modules/home/workstation.nix`, then
  issue the a2a-token + api-server secrets in every host's sops file
  (`secrets/<host>.enc.yaml` for NixOS; `secrets/shikanime.enc.yaml` for the
  darwin user). The fleet learns the new token automatically via
  `mkA2aPeerTokens`.
- **Tag a host**: a workstation must carry `tag:automata` (and
  `tag:workstation`) for the ACL grants/denies to cover it. Tags are set
  out-of-band in the Tailscale control plane, not in nix.
- **Verify reachability**: from a workstation,
  `curl -H "Authorization: Bearer $A2A_OWN_TOKEN" https://<cluster>.taila659a.ts.net:9900/.well-known/agent.json`.
