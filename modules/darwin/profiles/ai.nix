{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    rtk
  ];
}
