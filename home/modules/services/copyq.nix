{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.services.copyq;
in {
  options.my.services.copyq = {
    enable = mkEnableOption "copyq";
    package = mkOption {
      type = types.package;
      default = pkgs.copyq;
      defaultText = literalExpression "pkgs.copyq";
      description = "The copyq package to use.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    systemd.user.services.copyq = {
      Unit = {
        Description = "Copyq";
        PartOf = [ "graphical-session.target" ];
        After = [ "tray.target" ];
      };
      Install = { WantedBy = [ "graphical-session.target" ]; };
      Service = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/copyq";
      };
    };
  };
}
