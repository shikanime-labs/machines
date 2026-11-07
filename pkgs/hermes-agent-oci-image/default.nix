{
  pkgs,
  lib,
  hermes-agent,
  plugins ? { },
  ...
}:

let
  # Directory plugins live under $HERMES_HOME/plugins on a host, where the
  # NixOS module symlinks them at activation time. A container has no
  # activation step, so the image bakes the same trees into its own home.
  pluginCopies = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: src: "cp -r ${src}/. /var/lib/hermes/plugins/${name}") plugins
  );
in
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
    mkdir -p /var/lib/hermes/plugins
    ${pluginCopies}
    chown -R hermes:hermes /var/lib/hermes
  '';
  enableFakechroot = true;

  # No User: the gateway binds the privileged webhook port (8644); the
  # hermes user is kept for a future securityContext + NET_BIND_SERVICE.
  config = {
    Entrypoint = [
      "hermes"
      "gateway"
    ];
    Env = [ "HERMES_HOME=/var/lib/hermes" ];
    ExposedPorts = {
      "8644/tcp" = { };
    };
    WorkingDir = "/var/lib/hermes";
  };

  meta = with lib; {
    description = "Hermes agent gateway (brain) container";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
