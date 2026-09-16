{ pkgs, ... }:

pkgs.fetchFromGitHub {
  name = "memory-wiki";
  owner = "NousResearch";
  repo = "hermes-memory-wiki";
  rev = "9bc3913b8474eaf4d7eec32e97af4d77957c36df";
  hash = "sha256-+WJNfVJLQCVAa9U4eAgr9ULrRmDPCddiLcshujbuTcQ=";
}
