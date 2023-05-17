{ pkgs, config, lib, ... }:

with lib;
let cfg = config.my.services.gammastep;
in {
  options.my.services.gammastep = { enable = mkEnableOption "gammastep"; };

  config = mkIf cfg.enable {
    services.gammastep = {
      enable = true;
      enableVerboseLogging = true;
      dawnTime = "06:00";
      duskTime = "19:00";
      provider = "geoclue2";
      temperature = {
        day = 3000;
        night = 3000;
      };
      tray = true;
    };
  };
}
