# Network Interface Configuration

## Overview

Bridged networking via native nixpkgs options (`networking.bridges` +
`networking.interfaces` + `networking.useNetworkd`). Every host has a single
bridge `br0` that carries all traffic — pod-to-pod, SSH, flannel, Longhorn.

## Implementation

Configured inline in each hardware module — no custom abstraction module.

| Module                      | Interfaces         | Bond                  | Bridge | DHCP |
| --------------------------- | ------------------ | --------------------- | ------ | ---- |
| `modules/nixos/beelink.nix` | `enp1s0`, `enp2s0` | `bond0` (balance-alb) | `br0`  | yes  |
| `modules/nixos/rpi.nix`     | `end0`             | —                     | `br0`  | yes  |

### Beelink (dual 2.5G NIC, balance-alb bond)

```nix
networking = {
  useNetworkd = true;
  bonds.bond0 = {
    interfaces = [ "enp1s0" "enp2s0" ];
    driverOptions = { mode = "balance-alb"; miimon = "100"; };
  };
  bridges.br0.interfaces = [ "bond0" ];
  interfaces.br0.useDHCP = true;
};
```

### Raspberry Pi (single 1G USB3 NIC)

```nix
networking = {
  useNetworkd = true;
  bridges.br0.interfaces = [ "end0" ];
  interfaces.br0.useDHCP = true;
};
```

## Bonding rationale

The NETGEAR MS308 is an unmanaged switch — no LACP (802.3ad) support.
`balance-alb` (mode 6) aggregates both NICs entirely in the Linux driver via ARP
negotiation. Zero switch configuration required.

- Single-flow throughput: 2.5 Gbps (per-flow hash)
- Multi-flow aggregate: ~4-5 Gbps
- Fails over automatically if one NIC/link dies (`miimon=100`)
- One cable plugged in → bond works on single link; second cable is hot-add

## Longhorn storage network

The Multus `storageNetwork` NAD has been **removed**. Rationale:

1. `br0` carries all traffic (management + pod). A Multus secondary interface on
   the same bridge as flannel provides **zero isolation** — both interfaces hit
   identical iptables/conntrack/kube-proxy overhead
   (`bridge-nf-call-iptables=1`).
2. The knix Multus stack uses DHCP IPAM (thick plugin + dynamic networks
   controller + DHCP DaemonSet). Whereabouts IPAM is incompatible with this
   stack. DHCP IPAM on the same subnet as `br0` causes routing ambiguity (two
   interfaces, same subnet, same pod).
3. Longhorn on default flannel/host-gw already performs at wire speed for
   same-L2 clusters.

**When to re-add**: only with a **physically separate storage network** —
`enp2s0` cabled to a dedicated switch, `br-storage` bridge with
`bridge-nf-call-iptables=0` on that bridge only. Then the NAD bypasses all
Kubernetes netfilter overhead. See the "dual bridge" pattern in the skill.

## NIC performance tuning

Each hardware module includes an inline
`systemd.services.network-nic-performance` one-shot that applies ethtool
hardware offloads (TSO/GSO/SG/RX/TX, rx-udp-gro-forwarding) and RPS IRQ
distribution on the physical interfaces (pre-bond, pre-bridge).

## Why not a custom module?

A previous iteration used a 208-line custom `hardware.networkInterfaces` module.
It was never imported into any host configuration — dead code that caused
`The option 'hardware.networkInterfaces' does not exist` build failures. Native
`networking.bridges` achieves the same result in 3-4 lines per interface.

## Discovery

Verify interface names on actual hardware before deploying:

```bash
ip link show          # List interfaces and kernel names
ethtool -i <iface>    # Verify driver
```

Known names by hardware:

| Hardware                     | Interface(s)       | Driver     |
| ---------------------------- | ------------------ | ---------- |
| Beelink (Intel N150, i226-V) | `enp1s0`, `enp2s0` | `igc`      |
| Raspberry Pi CM4 (USB3 GigE) | `end0`             | `lan743x`  |
| Older Raspberry Pi           | `eth0`             | `smsc95xx` |
