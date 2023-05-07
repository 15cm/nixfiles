{ config, pkgs, lib, ... }:

with lib;
let package = pkgs.picom;
in rec {
  home.packages = [ package ];
  xdg.configFile."picom/picom.conf".source = ./picom.conf;

  systemd.user.services.picom = {
    Unit = {
      Description = "Picom X11 compositor";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Install = { WantedBy = [ "graphical-session.target" ]; };

    Service = {
      ExecStart = concatStringsSep " " [
        "${config.my.programs.nixGL.package}/bin/nixGL"
        "${package}/bin/picom"
      ];
      Restart = "always";
      RestartSec = 3;
    };
  };
}
