{ config, lib, mylib, ... }:

with lib;
let
  cfg = config.my.services.metrics;
  inherit (mylib) mkDefaultTrueEnableOption assertNotNull;
in {
  options.my.services.metrics = {
    enable = mkEnableOption "metrics";
    enableScrapeZrepl = mkDefaultTrueEnableOption "zrepl";
    enableScrapeHeadscale = mkEnableOption "headscale";
    enableScrapeNut = mkEnableOption "nut";
    enableScrapeNode = mkDefaultTrueEnableOption "node";
    enableScrapeSmartctl = mkEnableOption "smartctl";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.prometheus = {
        enable = true;
        port = config.my.ports.prometheus.listen;
        scrapeConfigs = [{
          job_name = "prometheus";
          static_configs = [{
            targets = [
              "localhost:${
                builtins.toString (config.my.ports.prometheus.listen)
              }"
            ];
          }];
        }];
      };

      services.traefik.dynamicConfigOptions.http = {
        routers.metrics = {
          rule = "Host(`metrics.${
              assertNotNull config.my.services.gateway.internalDomain
            }`)";
          middlewares = [ "lan-only@file" ];
          service = "metrics";
        };
        services = {
          metrics.loadBalancer.servers = [{
            url =
              "http://127.0.0.1:${toString config.my.ports.prometheus.listen}";
          }];
        };
      };
    }
    (mkIf cfg.enableScrapeZrepl {
      services.prometheus.scrapeConfigs = [{
        job_name = "zrepl";
        static_configs = [{
          targets = [
            "localhost:${builtins.toString (config.my.ports.prometheus.zrepl)}"
          ];
        }];
      }];
    })
    (mkIf cfg.enableScrapeHeadscale {
      services.prometheus.scrapeConfigs = [{
        job_name = "headscale";
        static_configs = [{
          targets = [
            "localhost:${
              builtins.toString (config.my.ports.prometheus.headscale)
            }"
          ];
        }];
      }];
    })
    (mkIf cfg.enableScrapeNut {
      users.users.nut-exporter = {
        uid = config.my.ids.uids.nut-exporter;
        isSystemUser = true;
        group = "nut";
      };
      services.prometheus.exporters.nut = {
        enable = true;
        port = config.my.ports.prometheus.nut;
        listenAddress = "127.0.0.1";
        nutUser = "admin";
        passwordPath = config.sops.secrets.upsAdminPassword.path;
      };
      services.prometheus.scrapeConfigs = [{
        job_name = "nut";
        metrics_path = "/ups_metrics";
        static_configs = [{
          targets = [
            "localhost:${builtins.toString (config.my.ports.prometheus.nut)}"
          ];
        }];
      }];
    })
    (mkIf cfg.enableScrapeNode {
      services.prometheus.exporters.node = {
        enable = true;
        port = config.my.ports.prometheus.node;
        listenAddress = "127.0.0.1";
        enabledCollectors = [ "systemd" ];
        disabledCollectors = [ "textfile" ];
      };
      services.prometheus.scrapeConfigs = [{
        job_name = "node";
        static_configs = [{
          targets = [
            "localhost:${builtins.toString (config.my.ports.prometheus.node)}"
          ];
        }];
      }];
    })
    (mkIf cfg.enableScrapeSmartctl {
      services.prometheus.exporters.smartctl = {
        enable = true;
        port = config.my.ports.prometheus.smartctl;
        listenAddress = "127.0.0.1";
      };
      services.prometheus.scrapeConfigs = [{
        job_name = "smartcttl";
        static_configs = [{
          targets = [
            "localhost:${
              builtins.toString (config.my.ports.prometheus.smartctl)
            }"
          ];
        }];
      }];
    })
  ]);
}
