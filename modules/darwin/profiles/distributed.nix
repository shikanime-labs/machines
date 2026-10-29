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

  # sd-card hosts (fushi, minish, nemishi) no longer serve as remote builders:
  # their flaky SSH fails the peers' distributed builds mid-closure (three
  # instances during the 2026-10-26 sync2 run, machines#1651), and a
  # speedFactor 1 / maxJobs 2 aarch64 peer adds nothing against four
  # speedFactor 2 x86_64 builders. Re-add only with a stable SSH story.
  mkBuildMachines = machines: builtins.filter (m: config.networking.hostName != m.hostName) machines;
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

    distributedBuilds = true;

    linux-builder = {
      enable = false;
      ephemeral = true;
      systems = [ "aarch64-linux" ];
    };

    settings.builders-use-substitutes = true;
  };
}
