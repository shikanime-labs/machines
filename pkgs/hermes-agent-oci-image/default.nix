{ pkgs, lib, system, hermes-agent, ... }:

pkgs.dockerTools.buildLayeredImage {
  name = "hermes-agent";
  tag = "latest";

  contents = [
    pkgs.dockerTools.caCertificates
    pkgs.dockerTools.usrBinEnv
    pkgs.busybox
    hermes-agent
  ];

  fakeRootCommands = ''
    ${pkgs.dockerTools.shadowSetup}
    groupadd -g 65532 hermes
    useradd -u 65532 -g 65532 -d /var/lib/hermes hermes
    mkdir -p /var/lib/hermes
    chown hermes:hermes /var/lib/hermes
  '';
  enableFakechroot = true;

  # No User: the gateway binds the privileged webhook port (8644); the
  # hermes user is kept for a future securityContext + NET_BIND_SERVICE.
  config = {
    Entrypoint = [ "hermes" "gateway" ];
    Env = [ "HERMES_HOME=/var/lib/hermes" ];
    ExposedPorts = { "8644/tcp" = { }; };
    WorkingDir = "/var/lib/hermes";
  };

  meta = with lib; {
    description = "Hermes agent gateway (brain) container";
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
