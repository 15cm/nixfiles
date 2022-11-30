{ pkgs, lib, ... }:

with lib;
let package = pkgs.aria2;
in rec {
  home.packages = [ package ];
  # TODO: add the real config file once encryption is introduced
  xdg.configFile."aria2/aria2.conf".source = ./aria2.conf;

  systemd.user.services.aria2 = {
    Unit = { Description = "Aria2"; };

    Install = { WantedBy = [ "default.target" ]; };

    Service = {
      ExecStart = concatStringsSep " " [
        "${package}/bin/aria2c"
        "--conf-path=%h/.config/aria2/aria2.conf"
      ];
      Restart = "always";
      RestartSec = 3;
    };
  };
}
