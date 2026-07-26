{ pkgs, ... }:

{
  home.packages = with pkgs; [
    graphify
    qwen-code
    rtk
  ];

  programs = {
    antigravity-cli.enable = true;

    codex.enable = true;

    claude-code.enable = true;
  };
}
