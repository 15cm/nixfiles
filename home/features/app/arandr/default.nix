{ pkgs, mylib, ... }:

let
  preStartScript =
    mylib.writeShellScriptFile "arandr-pre-start" ./load-layout.sh;
in {
  home.packages = [ pkgs.arandr ];
  systemd.user.services.arandr = {
    Unit = { Description = "ArandR -- A simple visual front end for XRandR"; };
    Install = { WantedBy = [ "graphical-session.target" ]; };
    Service = {
      Type = "oneshot";
      ExecStart = "${preStartScript}";
    };
  };
}
