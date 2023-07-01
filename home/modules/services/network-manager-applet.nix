{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.services.network-manager-applet;
in {
  options.my.services.network-manager-applet = {
    enable = mkEnableOption "network-manager-applet";
  };

  config = mkIf cfg.enable {
    services.network-manager-applet.enable = true;
    systemd.user.services.network-manager-applet = {
      Unit = {
        PartOf = mkForce [ "tray.target" ];
        After = mkForce [ "tray.target" ];
      };
      Install.WantedBy = mkForce [ "tray.target" ];
    };
  };
}
