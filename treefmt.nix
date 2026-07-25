{
  perSystem = { pkgs, ... }: {
    treefmt.config = {
      projectRootFile = "flake.nix";
      programs = {
        alejandra.enable = true;
        statix.enable = true;
        deadnix.enable = true;
        typos = {
          enable = true;
          configFile = pkgs.formats.toml { }.generate "typos.toml" {
            # `facter` is a legit tool name (nixos-facter), not a typo
            default.extend-words.facter = "facter";
          };
        };
      };
    };
  };
}
