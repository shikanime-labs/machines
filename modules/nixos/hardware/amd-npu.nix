{ pkgs, ... }:

let
  halogenFabricClock = pkgs.runCommand "halogen-fabric-clock" { } ''
    install -Dm755 ${./halogen-fabric-clock} $out/bin/halogen-fabric-clock
  '';

  halogenXrtLibs = pkgs.callPackage ../../../pkgs/halogen-xrt-libs {
    inherit (pkgs) patchelf;
    xrtCombined = pkgs.xrt-combined;
  };
in
{
  hardware.amd-npu = {
    enable = true;
    enableNPU = true;
    enableFastFlowLM = false;
    enableLemonade = false;
    enableImageGen = false;
  };

  environment.systemPackages = [ halogenFabricClock ];

  systemd.tmpfiles.rules = [ "L+ /opt/xilinx/xrt - - - - ${halogenXrtLibs}/opt/xilinx/xrt" ];

  systemd.services.halogen-fabric-clock = {
    description = "Hold the AMD GPU fabric clock at its top level (GPU and NPU together)";
    after = [ "systemd-modules-load.service" ];
    wantedBy = [
      "multi-user.target"
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
    unitConfig = {
      ConditionPathExists = "/dev/accel/accel0";
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${halogenFabricClock}/bin/halogen-fabric-clock hold";
    };
  };

  environment.etc."systemd/system/rke2-containerd.service.d/10-halogen-npu-memlock.conf".text = ''
    [Service]
    LimitMEMLOCK=infinity
  '';
}
