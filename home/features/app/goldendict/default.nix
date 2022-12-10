{ pkgs, mylib, ... }:

let
  package = pkgs.goldendict;
  preStartScript =
    mylib.writeShellScriptFile "goldendict-prestart" ./fix-zoom.sh;
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
      ExecStartPre = "${preStartScript}";
      ExecStart = "${package}/bin/goldendict";
    };
  };
}
