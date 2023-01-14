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
  };

  config = mkIf cfg.enable {
    sops.secrets.grafanaPassword = {
      sopsFile = ../../../common/secrets.yaml;
      owner = "grafana";
    };
    services.grafana = {
      enable = true;
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
      };

      provision = let hostnames = [ "sachi" "kazuki" "amane" "yumiko" "asako" ];
      in {
        enable = true;
        datasources.settings.datasources = map (host: {
          name = "${host}-metrics";
          type = "prometheus";
          url = "https://metrics.${host}.m.mado.moe";
        }) hostnames;
        dashboards.settings.providers = let
          dashboardsDir = pkgs.linkFarm "monitoring-dashboards" (map
            (host: rec {
              name = "${host}-metrics-zrepl.json";
              path = (toJSONFile name (import ./dashboards/zrepl-template.nix {
                dataSourceName = "${host}-metrics";
              }));
            }) hostnames);
        in [{
          name = "zrepl";
          folder = "zrepl";
          # The option allows us to save the provision dashboards to the database, so the Grafana web page won't ask if you want to leave everytime. The workflow is that we use the dashboard files in nixfiles to bootstrap a new installation of Grafana.
          allowUiUpdates = true;
          options.path = dashboardsDir;
        }];
      };
    };
  };
}
