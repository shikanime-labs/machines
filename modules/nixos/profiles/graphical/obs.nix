# OBS Studio with the fleet's plugin set and virtual camera support.
{
  pkgs,
  ...
}:

{
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true; # for Zoom/Teams
    plugins = with pkgs.obs-studio-plugins; [
      obs-vkcapture # Vulkan/OpenGL game capture
      advanced-scene-switcher # automated scene switching
      input-overlay # show keyboard/gamepad input on stream
      obs-composite-blur # blur filter with proper compositing
      obs-backgroundremoval # background removal filter
      obs-gstreamer # GStreamer source/encoder/filter
    ];
  };
}
