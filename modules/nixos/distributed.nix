{ config, ... }:

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

  mkBuildMachines = machines: builtins.filter (m: config.networking.hostName != m.hostName) machines;
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
}
