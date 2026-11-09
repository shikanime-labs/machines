{
  config,
  pkgs,
  ...
}:

{
  # RKE2 kubelet reserves scaled to this hardware class; without them
  # allocatable equals physical RAM and a large pod can OOM system daemons.
  services.knix.extraConfig.kubelet-arg = [
    "kube-reserved=cpu=250m,memory=1Gi"
    "system-reserved=cpu=250m,memory=512Mi"
    "eviction-hard=memory.available<500Mi"
  ];

  # UEFI laptop bootloader (Razer Blade 17, 2019). Windows dual-boot via systemd-boot.
  # Windows entry is automatically detected by systemd-boot.
  boot.loader = {
    efi.canTouchEfiVariables = true;
    systemd-boot.enable = true;
  };

  # Razer Blade 17 peripherals: daemon + udev rules.
  hardware.openrazer.enable = true;

  # CPU/device power management + suspend-on-lid-close.
  powerManagement.enable = true;

  hardware = {
    # GPU management belongs here, not in the graphical profile: this module is
    # the fleet's only NVIDIA host and the profile stays GPU-agnostic.
    graphics = {
      enable = true;
      enable32Bit = true; # Gaming: 32-bit for Wine/Proton
      # NVDEC hardware video decode (browser/media players) on the dGPU.
      extraPackages = with pkgs; [ nvidia-vaapi-driver ];
    };

    # NVIDIA GeForce RTX (Max-Q) dGPU — Razer Blade 17 specific.
    nvidia = {
      open = false; # proprietary/closed kernel module, per explicit request
      modesetting.enable = true;
      powerManagement = {
        enable = true;
        # Fine-grained RTD3: per-frame power-state transitions instead of a coarse
        # on/off switch. Valid because prime.offload.enable is set (assertion:
        # finegrained -> offload).
        finegrained = true;
      };
      prime.offload = {
        enable = true;
        enableOffloadCmd = true; # provides `nvidia-offload` wrapper
      };
    };
  };

  services = {
    fstrim.enable = true;
    udisks2.enable = true;

    # NVIDIA host monitoring: exporter + vmagent scrape job.
    prometheus.exporters.nvidia-gpu = {
      enable = true;
      listenAddress = "127.0.0.1";
    };
    vmagent.prometheusConfig.scrape_configs = [
      {
        job_name = "nvidia-gpu";
        static_configs = [ { targets = [ "127.0.0.1:9835" ]; } ];
        relabel_configs = [
          {
            target_label = "instance";
            replacement = config.networking.hostName;
          }
          {
            target_label = "cluster";
            replacement = "nishir";
          }
        ];
      }
    ];
  };
}
