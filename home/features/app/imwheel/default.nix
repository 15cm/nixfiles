{ pkgs, ... }:

let package = pkgs.imwheel;
in {
  home.packages = [ package ];
  systemd.user.services.imwheel = {
    Unit = {
      Description = "imwheel";
      PartOf = [ "graphical-session.target" ];
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
    Service = {
      Type = "simple";
      ExecStart = "${package}/bin/imwheel -d -b '4567'";
      ExecStop = "/bin/kill -INT $(MAINPID)";
    };
  };
}
