{
  pkgs,
  lib,
  hermes-agent,
  ...
}:
pkgs.dockerTools.buildLayeredImage {
  name = "hermes-agent-oci-image";
  tag = "latest";

  contents = [
    pkgs.dockerTools.caCertificates
    pkgs.dockerTools.usrBinEnv
    pkgs.openssh
    hermes-agent
  ];

  fakeRootCommands = ''
    ${pkgs.dockerTools.shadowSetup}
    groupadd -g 65532 hermes
    useradd -u 65532 -g 65532 -d /home/hermes -M hermes
    mkdir -p /home/hermes
    chown hermes:hermes /home/hermes
  '';
  enableFakechroot = true;

  config = {
    Entrypoint = [
      "${pkgs.lib.getExe hermes-agent}"
    ];
    Cmd = [ "chat" ];
    Env = [ "HOME=/home/hermes" ];
    User = "65532:65532";
  };

  meta = with lib; {
    description = "Hermes Agent container runtime, terminal sandboxed over SSH";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
