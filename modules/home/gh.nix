{ pkgs, ... }:

let
  # gh-stack 0.3.0 ships a stray Go `test` binary that shadows coreutils' test
  # in PATH and aborts nixos-rebuild's activation safety check; drop it.
  gh-stack = pkgs.gh-stack.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      rm -f $out/bin/test
    '';
  });
in

{
  home.packages = [ gh-stack ];

  programs.gh.extensions = [ gh-stack ];
}
