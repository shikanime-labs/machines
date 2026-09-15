# Steam with local network game transfers, protontricks, remote play, and a
# gamescope session forced onto the discrete NVIDIA GPU (canonical prime-offload
# env from https://wiki.nixos.org/wiki/Nvidia). Hardware enablement lives in
# ../hardware/; this module only wires the client and its session.
{
  programs.steam = {
    enable = true;
    localNetworkGameTransfers.openFirewall = true;
    protontricks.enable = true;
    remotePlay.openFirewall = true;
    # Make the Steam client itself enumerate the discrete NVIDIA GPU. On
    # prime-offload this laptop defaults Steam's client to the Intel iGPU (and
    # occasionally to the open-source NVK Mesa driver), so Steam's hardware
    # report shows "no NVIDIA card". The gamescope session wrapper below injects
    # the prime-offload env + NVIDIA-only Vulkan layer (the canonical set from
    # https://wiki.nixos.org/wiki/Nvidia: __NV_PRIME_RENDER_OFFLOAD=1,
    # __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0, __VK_LAYER_NV_optimus=NVIDIA_only),
    # which makes the proprietary driver the one Steam enumerates.
    gamescopeSession = {
      enable = true;
      env = {
        __NV_PRIME_RENDER_OFFLOAD = "1";
        __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        __VK_LAYER_NV_optimus = "NVIDIA_only";
      };
    };
  };

  # Steam Input / Steam Controller udev rules (Valve's 60-steam-input.rules +
  # 60-steam-vr.rules) so gamepads grant the seated user uaccess without root.
  hardware.steam-hardware.enable = true;
}
