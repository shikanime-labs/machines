{ config, ... }:

{
  imports = [
    ./node.nix
  ];

  services.knix = {
    role = "agent";
    serverAddr = "https://nishir.taila659a.ts.net:9345";
    tokenFile = config.sops.secrets.rke2-token.path;
  };
}
