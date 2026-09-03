{ self, pkgs, lib, ... }:

{
  # Expose all modules through flake outputs so consumers can use
  # self.nixosModules.<name>, self.darwinModules.<name>,
  # and self.homeManagerModules.<name> instead of relative paths.
  flake = {
    nixosModules = {
      # Profiles
      profile-ai = ../profiles/ai/default.nix;
      profile-base = ../profiles/base/default.nix;
      profile-distributed = ../profiles/distributed/default.nix;
      profile-follower = ../profiles/follower/default.nix;
      profile-forgejo = ../profiles/forgejo/default.nix;
      profile-graphical = ../profiles/graphical/default.nix;
      profile-leader = ../profiles/leader/default.nix;
      profile-machine = ../profiles/machine/default.nix;
      profile-minimal = ../profiles/minimal/default.nix;
      profile-nishir = ../profiles/nishir/default.nix;
      profile-server = ../profiles/server/default.nix;
      profile-wifi = ../profiles/wifi/default.nix;
      profile-workstation = ../profiles/workstation/default.nix;

      # Users
      user-automata = ../users/automata/default.nix;
      user-builder = ../users/builder/default.nix;
      user-meika = ../users/meika/default.nix;
      user-nishir = ../users/nishir/default.nix;
      user-shika = ../users/shika/default.nix;

      # Hardware
      hardware-beelink = ../hardware/beelink/default.nix;
      hardware-ms-s1 = ../hardware/ms-s1/default.nix;
      hardware-rpi4 = ../hardware/rpi4/default.nix;
      hardware-rpi5 = ../hardware/rpi5/default.nix;
    };

    darwinModules = {
      # Darwin profiles
      darwinProfile-ai = ../darwin/profiles/ai/default.nix;
      darwinProfile-base = ../darwin/profiles/base/default.nix;
      darwinProfile-distributed = ../darwin/profiles/distributed/default.nix;
      darwinProfile-minimal = ../darwin/profiles/minimal/default.nix;
      darwinProfile-workstation = ../darwin/profiles/workstation/default.nix;

      # Darwin user
      darwinUser-shikanimedeva = ../darwin/users/shikanimedeva/default.nix;
    };

    homeManagerModules = {
      # Profile home modules (the .nix files kept alongside default.nix)
      profileHome-ai = ../profiles/ai/home.nix;
      profileHome-base = ../profiles/base/home.nix;
      profileHome-graphical = ../profiles/graphical/home.nix;
      profileHome-workstation = ../profiles/workstation/home.nix;

      # App home modules (consolidated into default.nix — not exposed here
      # since they're already inlined into app default.nix modules above)
    };
  };
}
