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
