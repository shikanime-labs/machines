# Build the hermes-agent package against this repo's nixpkgs with the
# nodejs 24 LTS instead of the pinned nodejs 26: nodejs 26.10.0 does not
# compile on aarch64 (V8 drops the CHAR_BIT include under glibc 2.42) and
# is not on any binary cache yet. Everything else mirrors the upstream
# package — the source is the flake input itself, and the dependency
# groups below track its `default` (full) variant in nix/packages.nix.
{
  inputs,
  pkgs,
  lib,
}:
let
  hermesPkgs = pkgs.extend (_: prev: { nodejs_26 = prev.nodejs_24; });
  hermes-agent = hermesPkgs.callPackage "${inputs.hermes-agent.outPath}/nix/hermes-agent.nix" {
    inherit (inputs.hermes-agent.inputs)
      uv2nix
      pyproject-nix
      pyproject-build-systems
      ;
    npm-lockfile-fix = inputs.hermes-agent.inputs.npm-lockfile-fix.packages.${pkgs.stdenv.hostPlatform.system}.default;
    inherit (inputs.hermes-agent) rev lastModified;
  };
in
hermes-agent.override {
  extraDependencyGroups = [
    "anthropic"
    "azure-identity"
    "bedrock"
    "daytona"
    "dingtalk"
    "edge-tts"
    "exa"
    "fal"
    "feishu"
    "firecrawl"
    "messaging"
    "modal"
    "parallel-web"
    "tts-premium"
    "vercel"
    "voice"
  ]
  ++ lib.optionals pkgs.stdenv.isLinux [ "matrix" ];
}
