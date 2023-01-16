{ config, lib, ... }:

with lib;
let cfg = config.my.services.smartd;
in {
  options.my.services.smartd = { enable = mkEnableOption "smartd"; };

  config = mkIf cfg.enable {
    services.smartd = {
      enable = true;
      # Turns on SMART Automatic Offline Testing on startup, and schedules short self-tests daily, and long self-tests weekly
      defaults.monitored = "-a -o on -s (S/../.././02|L/../../7/04)";
    };
  };
}
