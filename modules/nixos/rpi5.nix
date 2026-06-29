{
  imports = [
    ./rpi.nix
  ];

  # The Raspberry Pi 5 has an onboard PCIe connector for NVMe HATs.
  # The nixos-hardware rasberry-pi-5 module already adds nvme/pcie-brcmstb/clk-rp1
  # to initrd.availableKernelModules and sets up the vendor kernel + device tree filter.
  # This module adds RPi 5-specific quirks on top.

  # RP1 Ethernet interface on Pi 5 is named end0 (not eth0).
  # The Tailscale UDP GRO forwarding service in rpi.nix already targets end0.
}
