{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  mkSshHeadlessHost = user: {
    User = user;
    SetEnv.TERM = "xterm-256color";
  };

  mkSshWorkstationHost = user: {
    ForwardX11 = true;
    User = user;
    SetEnv.TERM = "xterm-256color";
  };
in
{
  catppuccin = {
    enable = true;
    flavor = "latte";
  };

  colemak.enable = true;

  home = {
    packages = with pkgs; [
      bws
      cachix
      devenv
      docker-credential-helpers
      pass
      qpdf
      qwen-code
      rclone
      rtk
      secretspec
      wget
      zip
    ];
    sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];
  };

  # FIX: https://github.com/Mic92/sops-nix/issues/890
  launchd.agents.sops-nix = mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config.EnvironmentVariables.PATH = mkForce "/usr/bin:/bin:/usr/sbin:/sbin";
  };

  programs = {
    antigravity-cli.enable = true;

    bat.enable = true;

    carapace.enable = true;

    codex.enable = true;

    claude-code.enable = true;

    command-not-found.enable = true;

    dircolors.enable = true;

    direnv = {
      enable = true;
      mise.enable = true;
      nix-direnv.enable = true;
      config.global.load_dotenv = true;
    };

    docker-cli.enable = true;

    gpg.enable = true;

    jujutsu.settings."merge-tools".mergiraf."merge-tool-edits-conflict-markers" = true;

    mergiraf = {
      enable = true;
      enableGitIntegration = true;
      enableJujutsuIntegration = true;
    };

    mise.enable = true;

    nushell = {
      enable = true;
      extraConfig = ''
        $env.config.show_banner = false

        source ${pkgs.nu_scripts}/share/nu_scripts/custom-completions/vscode/vscode-completions.nu
      '';
    };

    pay-respects.enable = true;

    ripgrep.enable = true;

    ssh = {
      enable = true;
      settings = {
        "ashira.taila659a.ts.net" = mkSshHeadlessHost "nishir";
        "catbox.taila659a.ts.net" = mkSshHeadlessHost "shika";
        "fushi.taila659a.ts.net" = mkSshHeadlessHost "nishir";
        "manash.taila659a.ts.net" = mkSshHeadlessHost "nishir";
        "minish.taila659a.ts.net" = mkSshHeadlessHost "nishir";
        "nalsha.taila659a.ts.net" = mkSshHeadlessHost "nishir";
        "nemishi.taila659a.ts.net" = mkSshHeadlessHost "nishir";
        "thinkcentre-m710t.tailfb4bb2.ts.net" = mkSshWorkstationHost "william-phetsinorath";
      };
    };

    zoxide.enable = true;
  };

  xdg.enable = true;
}
