{ config, lib, mylib, ... }:

with lib;
let
  cfg = config.my.services.prometheus;
  inherit (mylib) mkDefaultTrueEnableOption;
in {
  options.my.services.prometheus = {
    enable = mkEnableOption "prometheus";
    enableScrapeZrepl = mkDefaultTrueEnableOption "zrepl";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      services.prometheus = {
        enable = true;
        scrapeConfigs = [{
          job_name = "prometheus";
          static_configs = [{
            targets = [
              "localhost:${
                builtins.toString (config.my.ports.prometheus.serve)
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
            "localhost:${
              builtins.toString (config.my.ports.zrepl.global.monitoring)
            }"
          ];
        }];
      }];
    })
  ]);
}
