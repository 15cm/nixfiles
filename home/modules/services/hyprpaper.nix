{ pkgs, config, lib, ... }:

with lib;
let cfg = config.my.services.hyprpaper;
in {
  options.my.services.hyprpaper = {
    enable = mkEnableOption "hyprpaper";
    package = mkOption {
      type = types.package;
      default = pkgs.hyprpaper;
    };
    monitorToWallPapers = mkOption {
      type = types.attrs;
      default = { };
      example = literalExpression ''
        {
          monitor = "DP-0";
          imagePath = /home/user/Pictures/1.png;
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile."hypr/hyprpaper.conf".text = concatStringsSep "\n"
      (mapAttrsToList (monitor: imagePath: ''
        preload = ${imagePath}
        wallpaper = ${monitor},${imagePath}
      '') cfg.monitorToWallPapers);
    systemd.user.services.hyprpaper = {
      Unit = {
        Description = "Hyprpaper";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Install = { WantedBy = [ "graphical-session.target" ]; };
      Service = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/hyprpaper";
      };
    };
  };
}
