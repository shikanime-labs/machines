{ pkgs, lib, system, hermes-agent, ... }:

pkgs.dockerTools.buildLayeredImage {
  name = "hermes";
  tag = "latest";

  contents = [
    pkgs.dockerTools.caCertificates
    pkgs.dockerTools.usrBinEnv
    pkgs.busybox
    hermes-agent
  ];

  fakeRootCommands = ''
    # proot fakechroot is not uid 0: shadow groupadd/useradd flush glibc nscd
    # (exit 4) at the cache-flush step and fail the layer; write /etc/passwd
    # and /etc/group directly instead of calling the shadow tools.
    { echo hermes:x:65532:; } >> /etc/group
    { echo hermes:x:65532:65532:Hermes agent:/var/lib/hermes:/bin/sh; } >> /etc/passwd
    mkdir -p /var/lib/hermes
    chown 65532:65532 /var/lib/hermes
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
