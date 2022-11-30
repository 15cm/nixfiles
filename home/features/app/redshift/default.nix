{ pkgs, ... }:

let package = pkgs.redshift;
in {
  home.packages = [ package ];
  systemd.user.services.redshift = {
    Unit = {
      Description = "Redshift -- color temperature adjuster";
      PartOf = [ "graphical-session.target" ];
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
    Service = {
      ExecStart = "${package}/bin/redshift-gtk";
      RestartSec = 3;
      Restart = "on-failure";
    };
  };
  xdg.configFile."redshift/redshift.conf".source = ./redshift.conf;
}
