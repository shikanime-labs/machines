{
  perSystem = { pkgs, ... }: {
    packages = {
      hermes-plugin-lcm = import ../../pkgs/hermes-plugin-lcm { inherit pkgs; };
      hermes-plugin-rtk-rewrite = import ../../pkgs/hermes-plugin-rtk-rewrite { inherit pkgs; };
    };
  };
}
