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

  # sd-card hosts (fushi, minish, nemishi) no longer serve as remote builders:
  # their flaky SSH fails the peers' distributed builds mid-closure (three
  # instances during the 2026-10-26 sync2 run, machines#1651), and a
  # speedFactor 1 / maxJobs 2 aarch64 peer adds nothing against four
  # speedFactor 2 x86_64 builders. Re-add only with a stable SSH story.
  mkBuildMachines =
    machines:
    let
      selfHostname = mkHostname config.networking.hostName;
    in
    builtins.filter (m: selfHostname != m.hostName) machines;

  mkSshKnownHost = { hostName, publicKey }: { "${mkHostname hostName}".publicKey = publicKey; };

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
      (mkBeelinkBuildMachine "kushira")
      (mkBeelinkBuildMachine "manash")
      (mkBeelinkBuildMachine "nalsha")
      (mkBeelinkBuildMachine "sashina")
    ];
    # sd-card hosts (fushi, minish, nemishi) no longer serve as remote builders:
    # their flaky SSH fails the peers' distributed builds mid-closure (three
    # instances during the 2026-10-26 sync2 run, machines#1651), and a
    # speedFactor 1 / maxJobs 2 aarch64 peer adds nothing against four
    # speedFactor 2 x86_64 builders. Re-add only with a stable SSH story.

    distributedBuilds = true;

    settings = {
      trusted-users = [ "builder" ];
      builders-use-substitutes = true;
      # Dead builders must fail fast, not hang the switch forever:
      # a builder whose ssh peer died without EOF otherwise parks
      # __build-remote in anon_pipe_read indefinitely (machines#1651).
      connect-timeout = 15;
    };
  };

  programs.ssh.extraConfig = ''
    Host *.taila659a.ts.net
      ServerAliveInterval 30
      ServerAliveCountMax 3
  '';

  programs.ssh.knownHosts = mkSshKnownHosts [
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
    (mkSshKnownHost {
      hostName = "kushira";
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGFPJ7GiWGH7MpJDlRz2Y+38U9AMnWELE/h7oGO6ec4K";
    })
    (mkSshKnownHost {
      hostName = "sashina";
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIII1QSdrWGafRNTuyBxRhm8NNLG+37Zfk3+i42sUbEB3";
    })
  ];
}
