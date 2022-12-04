{ pkgs, ... }:

let package = pkgs.easyeffects;
in {
  home.packages = [ package ];
  systemd.user.services.easyeffects = {
    Unit = {
      Description = "Easyeffects";
      PartOf = [ "graphical-session.target" ];
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
    Service = {
      Type = "simple";
      ExecStart = "${package}/bin/easyeffects";
    };
  };
}
