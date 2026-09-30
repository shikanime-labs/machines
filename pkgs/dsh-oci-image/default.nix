{
  pkgs,
  lib,
  dsh,
  ...
}:

pkgs.dockerTools.buildLayeredImage {
  name = "dsh";
  tag = "latest";

  contents = [
    pkgs.dockerTools.caCertificates
    pkgs.dockerTools.usrBinEnv
    dsh
  ];

  fakeRootCommands = ''
    ${pkgs.dockerTools.shadowSetup}
    groupadd -g 65532 dsh
    useradd -u 65532 -g 65532 -d /home/dsh -M dsh
    mkdir -p /home/dsh
    chown dsh:dsh /home/dsh
  '';
  enableFakechroot = true;

  config = {
    Entrypoint = [
      "${lib.getExe dsh}"
    ];
    Env = [ "HOME=/home/dsh" ];
    User = "65532:65532";
    WorkingDir = "/";
  };

  meta = with lib; {
    description = "DeepSeek agent harness (dsh) container";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
