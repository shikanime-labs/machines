{ config, lib, ... }:

with lib;

let
  mkHostname = hostName: "${hostName}.taila659a.ts.net";

  mkBeelinkBuildMachine = hostName: {
    hostName = mkHostname hostName;
    sshUser = "builder";
    system = "x86_64-linux";
    protocol = "ssh-ng";
    maxJobs = 4;
    speedFactor = 2;
    supportedFeatures = [
      "nixos-test"
      "benchmark"
      "big-parallel"
      "kvm"
    ];
    mandatoryFeatures = [ ];
  };

  mkRpiBuildMachine = hostName: {
    hostName = mkHostname hostName;
    sshUser = "builder";
    system = "aarch64-linux";
    protocol = "ssh-ng";
    maxJobs = 2;
    speedFactor = 1;
    supportedFeatures = [ "nixos-test" ];
    mandatoryFeatures = [ ];
  };

  mkBuildMachines =
    machines:
    let
      selfHostname = mkHostname config.networking.hostName;
    in
    builtins.filter (m: selfHostname != m.hostName) machines;

  mkSshKnownHost = { hostName, publicKey }: {
    "${mkHostname hostName}".publicKey = publicKey;
  };

  mkSshKnownHosts =
    knownHostsList:
    let
      selfHostname = mkHostname config.networking.hostName;
      mergedHosts = mergeAttrsList knownHostsList;
    in
    filterAttrs (name: _value: selfHostname != name) mergedHosts;
in
{
  nix = {
    buildMachines = mkBuildMachines [
      (mkBeelinkBuildMachine "ashira")
      (mkBeelinkBuildMachine "manash")
      (mkBeelinkBuildMachine "nalsha")
      (mkRpiBuildMachine "fushi")
      (mkRpiBuildMachine "minish")
      (mkRpiBuildMachine "nemishi")
    ];

    distributedBuilds = true;

    settings.builders-use-substitutes = true;
  };

  programs.ssh.knownHosts = mkSshKnownHosts [
    (mkSshKnownHost {
      hostName = "fushi";
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILrDoPfjV+jRuGXdsc+TlgaL/+eO9pPqav6SG+tl1nPC";
    })
    (mkSshKnownHost {
      hostName = "minish";
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFWXSOEAx3pEzeoaqKV4gCCEVK3do+f2oJWlL++lGA/N";
    })
    (mkSshKnownHost {
      hostName = "manash";
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDW8I5803nYCNIKmzXBgfVDYpOJvYH0jg8ht5Djr72eL";
    })
    (mkSshKnownHost {
      hostName = "ashira";
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILxxDA8yBStWRl43qL15IvnKrLRW9Y2KlRAtEnxm4n3X";
    })
    (mkSshKnownHost {
      hostName = "nalsha";
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGAFFXlS4bbJnvo2CaPdKPHX2EFyrfF/KHfcwsVgOffE";
    })
  ];
}
