{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./node.nix
  ];

  # The rke2-longhorn disks-config unit (from the knix module) hardcodes
  # KUBECONFIG=/etc/rancher/rke2/rke2.yaml and After/Wants=rke2-server.service.
  # On worker nodes rke2.yaml is never written (that is the server admin
  # kubeconfig) and rke2-server does not exist, so the unit's preStart loop
  # blocks forever and pins the node in `starting`. Point it at the agent's
  # local kubelet kubeconfig, which reaches the apiserver on :6443 with
  # node-authorizer rights, and order it after the agent instead.
  systemd.services.rke2-longhorn-default-disks-config =
    lib.mkIf (config.services.knix.serverAddr != "")
      {
        environment.KUBECONFIG = lib.mkForce "/var/lib/rancher/rke2/agent/kubelet.kubeconfig";
        after = lib.mkForce [ "rke2-agent.service" ];
        wants = lib.mkForce [ "rke2-agent.service" ];
      };

  services.gitea-actions-runner.package = pkgs.forgejo-runner;

  users.users.builder = {
    isNormalUser = true;
    home = "/home/builder";
    useDefaultShell = true;
  };

  virtualisation.docker = {
    daemon.settings = {
      fixed-cidr-v6 = "fd00::/80";
      ipv6 = true;
    };
    enable = true;
  };
}
