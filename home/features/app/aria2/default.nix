{ pkgs, lib, mylib, config, ... }:

with lib;
let
  package = pkgs.aria2;
  inherit (mylib) templateFile;
  templateData = { inherit (config.home) homeDirectory; };
in rec {
  home.packages = [ package ];
  xdg.configFile."aria2/aria2.conf".source =
    templateFile "aria2-conf" templateData ./aria2.conf.jinja;

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
