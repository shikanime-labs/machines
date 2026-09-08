{ pkgs, ... }:

pkgs.fetchFromGitHub {
  name = "ponytail";
  owner = "DietrichGebert";
  repo = "ponytail";
  rev = "2ed6c52c9d7e5e56942508591085fd45dea277d3";
  hash = "sha256-bGdXvzhWPwGdz3T2Yh2h6lf+3PBRFAfdBxP5pESmCHI=";
}
