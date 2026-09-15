# GameMode, GameScope, and the GPU-offload plumbing they rely on. Hardware
# enablement (drivers, PRIME) is a host/hardware concern; see ../hardware/.
{
  config,
  ...
}:

{
  programs = {
    # GameMode: daemon that applies on-demand optimizations while a game holds
    # a request (CPU governor -> performance, process renice). Trigger per-game
    # with the `gamemoderun` wrapper in the launch options (e.g. `gamemoderun %command%`).
    # enableRenice defaults true, giving gamemoded CAP_SYS_NICE so it can renice.
    gamemode = {
      enable = true;
      settings = {
        general.renice = 10; # nice the game process while GameMode is active
        # Optional NVIDIA side: pin the dGPU to fixed-performance so it doesn't
        # clock-drop under load (fps for heat). Best-effort under Wayland — the
        # NV-CONTROL write can no-op if there's no X display; harmless if so.
        # Drop this `custom` block to keep the adaptive PowerMizer default.
        custom = {
          # Resolves to the nvidia-settings store path (the nvidia package exposes
          # it as `config.hardware.nvidia.package.settings`). Pin the dGPU to
          # fixed-performance so it doesn't clock-drop under load (fps for heat).
          # Best-effort under Wayland — the NV-CONTROL write can no-op without an
          # X display; harmless. Drop this block to keep adaptive PowerMizer.
          start = "${config.hardware.nvidia.package.settings}/bin/nvidia-settings -a [gpu:0]/GPUPowerMizerMode=1";
          end = "${config.hardware.nvidia.package.settings}/bin/nvidia-settings -a [gpu:0]/GPUPowerMizerMode=0";
        };
      };
    };

    # GameScope standalone binary with CAP_SYS_NICE so it can renice / go RT itself.
    # Your steam `gamescopeSession` already wraps Steam in gamescope; this makes the
    # bare `gamescope` command also cap_sys_nice-capable. Needs prime-offload (on).
    gamescope = {
      enable = true;
      capSysNice = true;
    };
  };
}
