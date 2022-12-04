{ pkgs, ... }:

let package = pkgs.openrgb;
in {
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
}
