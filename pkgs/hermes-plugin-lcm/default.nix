{ pkgs, ... }:

pkgs.fetchFromGitHub {
  name = "hermes-lcm";
  owner = "stephenschoettler";
  repo = "hermes-lcm";
  rev = "v0.18.1";
  hash = "sha256-+1661BVi2XmqIaPYzNuUtrEfKvK9xQ8B4zedclIYuYA=";
}
