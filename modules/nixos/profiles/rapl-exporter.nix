# RAPL energy counters are root-only 0400 by default; node_exporter runs as
# the node-exporter user and the rapl collector fails without read access.
# Group + udev rule keep the counters readable without running as root.
{ pkgs, ... }:

{
  users.groups.rapl = { };

  users.users.node-exporter.extraGroups = [ "rapl" ];

  environment.etc."tmpfiles.d/rapl-perms.conf".text = ''
    z /sys/class/powercap/intel-rapl* 0440 root rapl - -
  '';

  services.udev.extraRules = ''
    SUBSYSTEM=="powercap", RUN+="${pkgs.coreutils}/bin/chgrp rapl /sys/class/powercap/intel-rapl*"
    SUBSYSTEM=="powercap", RUN+="${pkgs.coreutils}/bin/chmod 0440 /sys/class/powercap/intel-rapl*"
  '';
}
