{ config, lib, mylib, ... }:

with lib;
let
  cfg = config.my.services.prometheus;
  inherit (mylib) mkDefaultTrueEnableOption;
in {
  options.my.services.prometheus = {
    enable = mkEnableOption "prometheus";
    enableScrapeZrepl = mkDefaultTrueEnableOption "zrepl";
    enableScrapeHeadscale = mkEnableOption "headscale";
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
  ]);
}
