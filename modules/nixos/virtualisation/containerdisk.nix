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
  config = {
    boot = {
      # KubeVirt q35 exposes the guest console on ttyS0; without it the kernel
      # sends output to invisible VGA and panic=1 reboots silently.
      kernelParams = [ "console=ttyS0" ];

      # KubeVirt exposes containerDisks as virtio (/dev/vda); without these the
      # initrd cannot see the root disk and boot times out into a panic=1 loop.
      initrd.availableKernelModules = [
        "virtio_pci"
        "virtio_blk"
      ];

      # Load the virtio and KVM module families at runtime; kvm_intel/kvm_amd and
      # the NVIDIA stack are arch/device-specific and handled by
      # kernel-module-loader so a missing module never fails boot.
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

    # KubeVirt seeds cloud-config via NoCloud; always enabled.
    services.cloud-init.enable = true;

    systemd.services = {
      kernel-module-loader = {
        description = "Load VM kernel modules";
        enable = true;
        wantedBy = [ "multi-user.target" ];
        script = ''
          # Load KVM modules matching the CPU vendor.
          if grep -qE '(^| )vmx( |$)' /proc/cpuinfo; then
            modprobe kvm_intel
          fi

          # Load KVM modules with AMD-V acceleration if available.
          if grep -qE '(^| )svm( |$)' /proc/cpuinfo; then
            modprobe kvm_amd
          fi

          # Load NVIDIA kernel modules if available.
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
