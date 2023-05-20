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
    monitors = mkOption {
      type = types.attrs;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile."hypr/hyprpaper.conf".text = concatStringsSep "\n"
      (mapAttrsToList (name: value: ''
        preload = ${value.wallpaper}
        wallpaper = ${value.output},${value.wallpaper}
      '') cfg.monitors);
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
