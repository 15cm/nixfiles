{ pkgs, ... }:

let package = pkgs.goldendict;
in {
  home.packages = [ package ];
  systemd.user.services.goldendict = {
    Unit = {
      Description = "GoldenDict";
      PartOf = [ "graphical-session.target" ];
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
    Service = {
      Type = "simple";
      ExecStartPre = "${pkgs.runtimeShell} ${./fix-zoom.sh}";
      ExecStart = "${package}/bin/goldendict";
    };
  };
}
