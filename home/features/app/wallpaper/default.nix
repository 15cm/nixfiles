{ pkgs, ... }:

let package = pkgs.nitrogen;
in {
  home.packages = [ package ];
  systemd.user.services.nitrogen = {
    Unit = {
      Description = "Nitrogen";
      PartOf = [ "graphical-session.target" ];
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
    Service = {
      Type = "oneshot";
      ExecStart = "${package}/bin/nitrogen --restore";
    };
  };
}
