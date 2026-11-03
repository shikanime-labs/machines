{ pkgs, lib, ... }:

let
  # sshd must bind :22, so the container runs as root; sessions drop to
  # catbox (AllowUsers, pubkey-only). Host keys are generated at build time.
  entrypoint = pkgs.writeTextFile {
    name = "catbox-entrypoint";
    destination = "/usr/local/bin/entrypoint";
    executable = true;
    text = ''
      #!/bin/sh
      set -e
      # Seed the brain's key from the mounted secret, then serve.
      if [ -n "$HERMES_SSH_PUBKEY_FILE" ] && [ -f "$HERMES_SSH_PUBKEY_FILE" ]; then
        install -d -m 700 /home/catbox/.ssh
        cp "$HERMES_SSH_PUBKEY_FILE" /home/catbox/.ssh/authorized_keys
        chmod 600 /home/catbox/.ssh/authorized_keys
      fi
      exec sshd -D
    '';
  };
in
# Hands container for the hermes-agent brain: sshd plus the toolchain the
# brain drives over ssh, with /workspaces as the stateful mount point.
pkgs.dockerTools.buildLayeredImage {
  name = "catbox";
  tag = "latest";

  contents = [
    pkgs.dockerTools.caCertificates
    pkgs.dockerTools.usrBinEnv
    pkgs.busybox
    pkgs.openssh
    pkgs.gitFull
    pkgs.jj
    pkgs.gh
    pkgs.kubectl
    pkgs.nix
    pkgs.python3
    pkgs.rsync
    pkgs.util-linux
    entrypoint
  ];

  fakeRootCommands = ''
    ${pkgs.dockerTools.shadowSetup}
    groupadd -g 65532 catbox
    useradd -u 65532 -g 65532 -d /workspaces catbox
    mkdir -p /run/sshd /etc/ssh /workspaces
    ${pkgs.openssh}/bin/ssh-keygen -A
    cat > /etc/ssh/sshd_config <<'EOF'
    AllowUsers catbox
    PasswordAuthentication no
    PermitRootLogin no
    PubkeyAuthentication yes
    UsePAM no
    EOF
    chown catbox:catbox /workspaces
  '';
  enableFakechroot = true;

  config = {
    Entrypoint = [ "/usr/local/bin/entrypoint" ];
    Env = [ "HOME=/workspaces" ];
    ExposedPorts = { "22/tcp" = { }; };
    WorkingDir = "/workspaces";
  };

  meta = with lib; {
    description = "Catbox hands container (sshd + toolchain) for the hermes-agent brain";
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
