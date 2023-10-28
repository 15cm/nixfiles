{ config, lib, pkgs, mylib, ... }:

with lib;
let
  cfg = config.my.services.aria2;
  inherit (mylib) templateFile;
  templateData = { inherit (config.home) homeDirectory; };
in {
  options.my.services.aria2 = {
    enable = mkEnableOption "Aria2";
    package = mkOption {
      type = types.package;
      default = pkgs.aria2;
    };
  };
  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."aria2/aria2.conf".source =
      templateFile "aria2-conf" templateData ./aria2.conf.jinja;

    systemd.user.services.aria2 = {
      Unit = { Description = "Aria2"; };

      Install = { WantedBy = [ "default.target" ]; };

      Service = {
        ExecStart = concatStringsSep " " [
          "${cfg.package}/bin/aria2c"
          "--conf-path=%h/.config/aria2/aria2.conf"
        ];
        Restart = "always";
        RestartSec = 3;
      };
    };
  };
}
