{ pkgs, ... }: {
  home.packages = [ pkgs.arandr ];
  systemd.user.services.arandr = {
    Unit = {
      Description = "ArandR -- A simple visual front end for XRandR";
      PartOf = [ "graphical-session.target" ];
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
    Service = {
      Type = "oneshot";
      ExecStart = "%h/.screenlayout/default.sh";
    };
  };
}
