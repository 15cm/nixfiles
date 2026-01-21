{
  pkgs,
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.my.services.hyprpaper;
in
{
  options.my.services.hyprpaper = {
    enable = mkEnableOption "hyprpaper";
    package = mkOption {
      type = types.package;
      default = pkgs.hyprpaper;
      description = "The hyprpaper package to use";
    };
    wallpapers = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            monitor = mkOption {
              type = types.str;
              default = "";
              description = "Monitor to display this wallpaper on. If empty, will use as fallback";
            };
            path = mkOption {
              type = types.str;
              description = "Path to an image file or directory containing image files";
            };
            fit_mode = mkOption {
              type = types.enum [
                "contain"
                "cover"
                "tile"
                "fill"
              ];
              default = "cover";
              description = "How to display the image";
            };
            timeout = mkOption {
              type = types.int;
              default = 30;
              description = "Timeout between wallpaper changes in seconds (if path is a directory)";
            };
          };
        }
      );
      default = [ ];
      description = "List of wallpaper configurations";
    };
    splash = mkOption {
      type = types.bool;
      default = true;
      description = "Enable rendering of the hyprland splash over the wallpaper";
    };
    splash_offset = mkOption {
      type = types.int;
      default = 20;
      description = "How far up should the splash be displayed";
    };
    splash_opacity = mkOption {
      type = types.float;
      default = 0.8;
      description = "How opaque the splash is";
    };
    ipc = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable IPC";
    };
    sourceFiles = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional config files to source";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."hypr/hyprpaper.conf".text = concatStringsSep "\n" (
      [
        "splash = ${if cfg.splash then "true" else "false"}"
        "splash_offset = ${toString cfg.splash_offset}"
        "splash_opacity = ${toString cfg.splash_opacity}"
        "ipc = ${if cfg.ipc then "true" else "false"}"
      ]
      ++ (map (file: "source = ${file}") cfg.sourceFiles)
      ++ [ "" ]
      ++ (map (wallpaper: ''
        wallpaper {
            monitor = ${wallpaper.monitor}
            path = ${wallpaper.path}
            fit_mode = ${wallpaper.fit_mode}
        }'') cfg.wallpapers)
    );

    systemd.user.services.hyprpaper = {
      Unit = {
        Description = "Hyprpaper";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/hyprpaper";
      };
    };
  };
}
