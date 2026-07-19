{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

with lib;

let
  cfg = config.containerdisk;
in
{
  imports = [
    "${modulesPath}/virtualisation/disk-image.nix"
  ];

  options.containerdisk = {
    name = mkOption {
      type = types.str;
      description = "Container image name to assign to the built containerdisk.";
    };

    settings = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Extra attributes bound directly to the dockerTools.buildImage config attrset.";
    };
  };

  # Reference: https://github.com/kubevirt/kubevirt/blob/main/docs/container-register-disks.md
  config.system.build.containerdiskImage = pkgs.dockerTools.buildImage {
    inherit (cfg) name;

    copyToRoot = pkgs.runCommand "containerdisk" { } ''
      mkdir -p $out/disk
      cp -v ${config.system.build.image}/${config.image.fileName} $out/disk/${config.image.fileName}
    '';

    config = cfg.settings;
  };
}
