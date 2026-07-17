{
  perSystem =
    { pkgs, ... }:
    let
      jjplus = pkgs.callPackage ../../pkgs/jjplus { };
    in
    {
      overlayAttrs.jjplus = jjplus;
      packages.jjplus = jjplus;
    };
}
