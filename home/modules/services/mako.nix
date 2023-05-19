{ pkgs, config, lib, mylib, ... }:

with lib;
let
  cfg = config.my.services.mako;
  inherit (mylib) templateFile;
  templateData = { };
in {
  options.my.services.mako = { enable = mkEnableOption "mako"; };

  config = mkIf cfg.enable {
    services.mako = {
      enable = true;
      defaultTimeout = 3;
      font = "Noto Sans, Noto Sans CJK JP, Noto Color Emoji";
    };
    systemd.user.services.mako = {
      Unit = {
        Description = "Mako";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Install = { WantedBy = [ "graphical-session.target" ]; };
      Service = {
        Type = "simple";
        ExecStart = "${config.services.mako.package}/bin/mako";
      };
    };
  };
}
