{
  pkgs,
  lib,
  ...
}:

pkgs.dockerTools.buildLayeredImage {
  name = "huggingface-oci-image";
  tag = "latest";

  contents = [
    pkgs.dockerTools.caCertificates
    pkgs.dockerTools.usrBinEnv
    pkgs.busybox
    pkgs.python3Packages.huggingface-hub
  ];

  fakeRootCommands = ''
    ${pkgs.dockerTools.shadowSetup}
    groupadd -g 65532 huggingface
    useradd -u 65532 -g 65532 -d /home/huggingface -M huggingface
    mkdir -p /home/huggingface
    chown huggingface:huggingface /home/huggingface
  '';
  enableFakechroot = true;

  config = {
    Entrypoint = [ "/bin/sh" ];
    Env = [ "HOME=/home/huggingface" ];
    User = "65532:65532";
    WorkingDir = "/";
  };

  meta = with lib; {
    description = "Hugging Face CLI downloader container";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
