{ lib, ... }:

with lib;

{
  # Node exporter listens on localhost only — vmagent scrapes from 127.0.0.1.
  services = {
    comin.exporter.listen_address = "127.0.0.1";

    # Defaults (cpu, cpufreq, diskstats, filesystem, loadavg, meminfo,
    # netdev, stat, systemd, processes, thermal_zone) — same set the
    # victoria-metrics-k8s-stack node-exporter DaemonSet uses on servers.
    prometheus.exporters.node = {
      enable = true;
      port = 9100;
      listenAddress = "127.0.0.1";
    };

    # Victoria Metrics agent scrapes local exporters and pushes to vminsert.
    vmagent = {
      enable = true;
      prometheusConfig = {
        scrape_configs = [
          {
            job_name = "node";
            static_configs = [
              {
                targets = [ "127.0.0.1:9100" ];
                labels = {
                  instance = config.networking.hostName;
                  __metrics_source__ = "node";
                };
              }
            ];
          }
          {
            job_name = "comin";
            static_configs = [
              {
                targets = [ "127.0.0.1:4243" ];
                labels = {
                  instance = config.networking.hostName;
                  __metrics_source__ = "comin";
                };
              }
            ];
          }
        ];
      };
      remoteWrite.url = "https://nishir-telemetry.taila659a.ts.net/insert/0/prometheus/";
    };
  };
}
