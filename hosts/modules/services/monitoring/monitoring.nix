{ config, pkgs, lib, mylib, ... }:

with lib;
let
  cfg = config.my.services.monitoring;
  inherit (mylib) assertNotNull toJSONFile;
in {
  options.my.services.monitoring = {
    enable = mkEnableOption "monitoring";
    domain = mkOption {
      type = with types; nullOr str;
      default = null;
    };
    dataDir = mkOption {
      type = with types; nullOr str;
      default = null;
    };
    waitForManualZfsLoadKey =
      mkEnableOption "wait service for manual zfs load key";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.traefik.dynamicConfigOptions.http = {
        routers.monitoring = {
          rule = "Host(`monitoring.${
              assertNotNull config.my.services.gateway.internalDomain
            }`)";
          middlewares = [ "lan-only@file" ];
          service = "monitoring";
        };
        services = {
          monitoring.loadBalancer.servers = [{
            url = "http://127.0.0.1:${toString config.my.ports.grafana.listen}";
          }];
        };
      };
      users.users.grafana.extraGroups = [ "smtp-secret" ];
      sops.secrets.grafanaPassword = {
        sopsFile = ../../../common/secrets.yaml;
        owner = "grafana";
      };
      services.grafana = {
        enable = true;
        dataDir = assertNotNull cfg.dataDir;
        settings = {
          server = {
            http_addr = "127.0.0.1";
            http_port = config.my.ports.grafana.listen;
            domain = assertNotNull cfg.domain;
          };

          security = {
            admin_user = "sinkerine";
            admin_password =
              "$__file{${config.sops.secrets.grafanaPassword.path}}";
          };

          smtp = {
            enabled = true;
            host = "smtp.gmail.com:465";
            user = "admin@15cm.net";
            password = "$__file{${config.sops.secrets.smtpPassword.path}}";
            from = "monitoring@15cm.net";
          };
        };

        provision =
          let hostnames = [ "sachi" "kazuki" "amane" "yumiko" "asako" ];
          in {
            enable = true;
            datasources.settings.datasources = map (host: {
              name = "${host}-metrics";
              type = "prometheus";
              url = "https://metrics.${host}.m.mado.moe";
            }) hostnames;
          };
      };
    }
    (mkIf cfg.waitForManualZfsLoadKey {
      systemd.services.grafana = {
        wantedBy = mkForce [ "zfs-load-key-and-mount.target" ];
        after = [ "zfs-load-key-and-mount.target" ];
      };
    })
  ]);
}
