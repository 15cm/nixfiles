{ config, lib, ... }:

with lib;
let cfg = config.my.services.syncthing;
in {
  options.my.services.syncthing = { enable = mkEnableOption "Syncthing"; };

  my.services.syncthing = {
    enable = true;
    tray = {
      enable = true;
      command = "syncthingtray --wait";
    };
  };
}
