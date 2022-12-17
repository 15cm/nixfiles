{ pkgs, mylib, ... }:

let
  preStartScript =
    mylib.writeShellScriptFile "arandr-pre-start" ./load-layout.sh;
in {
  home.packages = [ pkgs.arandr ];
  systemd.user.services.arandr = {
    Unit = {
      Description = "ArandR -- A simple visual front end for XRandR";
      PartOf = [ "tray.target" ];
    };
    Install = { WantedBy = [ "graphical-session.target" "tray.target" ]; };
    Service = {
      Type = "oneshot";
      ExecStart = "${preStartScript}";
    };
  };
}
