{ lib, ... }:

{
  imports = [
    ./rpi.nix
  ];

  hardware.raspberry-pi."4".fkms-3d.enable = true;

  boot = {
    # Disable UAS for external USB drives - use more stable usb-storage
    # Blacklist UAS kernel module to prevent crashes on VL805
    blacklistedKernelModules = [ "uas" ];

    # fushi/minish ran the RPi4 kernel with CONFIG_ARM64_VA_BITS=39 (512GB VA).
    # Envoy's tcmalloc assumes 48-bit VA and aborts at startup on those nodes,
    # forcing every dataplane into CrashLoopBackOff (manifests PR #2015, follow-up
    # to #1951). Layer 48-bit VA onto whatever kernel nixos-hardware selects so
    # this stays correct if the kernel source changes; lets the EnvoyProxy
    # nodeAffinity workaround be reverted once the rebuilt image is rolled out.
    kernelPatches = [
      {
        name = "arm64-va-bits-48";
        config.ARM64_VA_BITS_48 = lib.kernel.yes;
      }
    ];
  };
}
