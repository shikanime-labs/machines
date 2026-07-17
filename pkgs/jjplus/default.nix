{ lib, rustPlatform }:
rustPlatform.buildRustPackage {
  pname = "jjplus";
  version = "0.1.0";
  src = ./.;
  cargoHash = "sha256-NfrKMjGNXDfdF02yHlZ5KxHp/2IP+EueLZnD9iFIa5g=";
  meta = {
    description = "jj workspace helper with a `switch` subcommand";
    license = lib.licenses.asl20;
  };
}
