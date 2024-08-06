{ config, lib, pkgs, ... }:

with lib;
let
  package = pkgs.openrgb;
  cfg = config.my.services.openrgb;

in {
  options.my.services.openrgb = { enable = mkEnableOption "Openrgb"; };
  config = mkIf cfg.enable {

    home.packages = [ package ];
    systemd.user.services.openrgb = {
      Unit = {
        Description = "Openrgb";
        PartOf = [ "graphical-session.target" ];
      };
      Install = { WantedBy = [ "graphical-session.target" ]; };
      Service = {
        Type = "oneshot";
        ExecStart = "${package}/bin/openrgb -p default";
      };
    };
  };
}
