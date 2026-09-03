# Evaluation wiring: every domain default.nix is imported here, and this file
# is imported by flake.nix. These are module-graph edges, not configuration.
{
  imports = [
    ./profiles/agent
    ./profiles/ai
    ./profiles/base
    ./profiles/distributed
    ./profiles/follower
    ./profiles/forgejo
    ./profiles/graphical
    ./profiles/leader
    ./profiles/machine
    ./profiles/minimal
    ./profiles/nishir
    ./profiles/server
    ./profiles/wifi
    ./profiles/workstation
    ./users/automata
    ./users/builder
    ./users/meika
    ./users/nishir
    ./users/shika
    ./apps/cloud
    ./apps/fontconfig
    ./apps/gh
    ./apps/ghostty
    ./apps/helix
    ./apps/krew
    ./apps/starship
    ./apps/vcs
    ./apps/zed-editor
    ./hardware/beelink
    ./hardware/ms-s1
    ./hardware/rpi4
    ./hardware/rpi5
  ];
}
