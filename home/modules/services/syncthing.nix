{ config, lib, ... }:

with lib;
let cfg = config.my.services.syncthing;
in {
  options.my.services.syncthing = { enable = mkEnableOption "Syncthing"; };

  config = mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      extraOptions = [ "--allow-newer-config" ];
      tray = {
        enable = true;
        command = "syncthingtray --wait";
      };
    };
    systemd.user.services.syncthingtray = {
      Unit = {
        Requires = mkForce [ ];
        PartOf = mkForce [ "tray.target" ];
        After = mkForce [ "tray.target" ];
      };
      Install.WantedBy = mkForce [ "tray.target" ];
    };
  };
}
