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
    "${modulesPath}/profiles/qemu-guest.nix"
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
  config = {
    boot = {
      binfmt.emulatedSystems = mkIf pkgs.stdenv.hostPlatform.isx86_64 [
        "aarch64-linux"
      ];

      kernelParams = [
        "boot.panic_on_fail"
        "console=ttyS0"
        "panic=1"
      ];

      # kvm_intel/kvm_amd and the NVIDIA stack are arch/device-specific and
      # handled by kernel-module-loader so a missing module never fails boot.
      kernelModules = [
        "virtio_pci"
        "virtio_net"
        "virtio_balloon"
        "virtio_blk"
        "virtio_rng"
        "virtio_console"
        "kvm"
        "vhost_net"
        "usb"
        "usbhid"
        "usb_storage"
        "uvcvideo"
      ];
    };

    environment.systemPackages = [ pkgs.usbutils ];

    services = {
      cloud-init.enable = true;
      qemuGuest.enable = true;
      getty.autologinUser = mkDefault "root";
    };

    systemd.services."serial-getty@ttyS0".enable = true;

    systemd.services = {
      kernel-module-loader = {
        description = "Load VM kernel modules";
        enable = true;
        wantedBy = [ "multi-user.target" ];
        script = ''
          if grep -qE '(^| )vmx( |$)' /proc/cpuinfo; then
            modprobe kvm_intel
          fi

          if grep -qE '(^| )svm( |$)' /proc/cpuinfo; then
            modprobe kvm_amd
          fi

          if modinfo nvidia 2>/dev/null >/dev/null; then
            modprobe nvidia_uvm
            modprobe nvidia_drm
            modprobe nvidia_modeset
          fi
        '';
      };
    };

    system.build.containerdiskImage = pkgs.dockerTools.buildImage {
      inherit (cfg) name;

      copyToRoot = pkgs.runCommand "containerdisk" { } ''
        mkdir -p $out/disk
        cp -v ${config.system.build.image}/${config.image.fileName} $out/disk/${config.image.fileName}
      '';

      config = cfg.settings;
    };
  };
}
