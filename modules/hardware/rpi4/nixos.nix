{ lib, ... }:

{
  imports = [
    ./rpi.nix
  ];

  hardware.raspberry-pi."4".fkms-3d.enable = true;

  nixpkgs.overlays = [
    # Envoy's tcmalloc assumes 48-bit VA and aborts at startup on RPi4 nodes
    # (manifests PR #2015, follow-up to #1951): the RPi vendor kernel is built
    # from bcm2711_defconfig, which selects CONFIG_ARM64_VA_BITS_39. Switch the
    # Kconfig choice to 48-bit VA.
    #
    # boot.kernelPatches cannot do this: nixos-hardware wraps the kernel in
    # `.overrideAttrs`, which detaches the `.override` hook the NixOS kernel
    # module uses to apply patch entries — they are silently dropped. The
    # kernel itself is built by `buildLinux`, so guard on the RPi defconfig and
    # merge the two keys into its structuredExtraConfig. VA_BITS is a Kconfig
    # choice: 39 must be disabled for 48 to hold.
    (_final: prev: {
      buildLinux =
        args:
        prev.buildLinux (
          if (args.defconfig or "") == "bcm2711_defconfig" then
            args
            // {
              structuredExtraConfig = (args.structuredExtraConfig or { }) // {
                ARM64_VA_BITS_39 = lib.kernel.no;
                ARM64_VA_BITS_48 = lib.kernel.yes;
              };
            }
          else
            args
        );
    })
  ];

  boot = {
    # Disable UAS for external USB drives - use more stable usb-storage
    # Blacklist UAS kernel module to prevent crashes on VL805
    blacklistedKernelModules = [ "uas" ];
  };
}
