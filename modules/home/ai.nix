{ pkgs, ... }:

{
  home.packages = with pkgs; [
    qwen-code
  ];

  programs = {
    antigravity-cli.enable = true;

    codex.enable = true;

    claude-code.enable = true;
  };
}
