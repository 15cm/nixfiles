{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.programs.goldendict;
in {
  options.my.programs.goldendict = {
    enable = mkEnableOption "Goldendict";
    package = mkOption {
      type = types.package;
      default = pkgs.goldendict;
      defaultText = literalExpression "pkgs.goldendict";
      description = "The goldendict package to use.";
    };
    enableSystemdService = mkEnableOption "systemd service";
  };

  config = mkIf cfg.enable (mkMerge [
    { home.packages = [ cfg.package ]; }
    (mkIf cfg.enableSystemdService {
      systemd.user.services.goldendict = {
        Unit = {
          Description = "Goldendict";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Install = { WantedBy = [ "graphical-session.target" ]; };
        Service = {
          Type = "simple";
          ExecStart = "${cfg.package}/bin/goldendict";
        };
      };
    })
  ]);
}
