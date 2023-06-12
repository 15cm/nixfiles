{ config, lib, ... }:

with lib;
let cfg = config.my.services.syncthing;
in {
  options.my.services.syncthing = { enable = mkEnableOption "Syncthing"; };

  config = mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      tray = {
        enable = true;
        command = "syncthingtray --wait";
      };
    };
    systemd.user.services.syncthingtray = { Unit.After = [ "tray.target" ]; };
  };
}
