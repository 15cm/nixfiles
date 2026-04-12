{
  config,
  lib,
  mylib,
  ...
}:

with lib;
let
  cfg = config.my.programs.hyprland;
  inherit (mylib) templateFile;
  extraConfig = pipe ./hyprland.conf.jinja [
    (templateFile "hyprland.conf" {
      inherit (cfg) monitors scale;
      inherit (cfg)
        musicPlayer
        musicPlayerDesktopFileName
        lockCommand
        ;
      musicPlayerLower = toLower cfg.musicPlayer;
      windowSwitcherScript = "python ${./window_switcher.py}";
      cliphistWofiImgScript = "bash ${config.my.services.cliphist.wofiImgScript} | wl-copy";
    })
    builtins.readFile
  ];
in
{
  options.my.programs.hyprland = {
    enable = mkEnableOption "Hyprland";
    musicPlayer = mkOption {
      type = types.str;
      default = "clementine";
    };
    musicPlayerDesktopFileName = mkOption {
      type = types.str;
      default = "org.clementine_player.Clementine.desktop";
    };
    lockCommand = mkOption {
      type = types.str;
      default = "hyprlock";
    };
    monitors = mkOption {
      type = types.attrs;
      default = { };
    };
    scale = mkOption {
      type = types.float;
      default = 1.0;
    };
    zfsPoolName = mkOption {
      type = with types; nullOr str;
      default = "rpool";
    };
    enableWaybar = mkOption {
      type = types.bool;
      default = true;
    };
    enableHyprpaper = mkOption {
      type = types.bool;
      default = true;
    };
    enableHyprsunset = mkOption {
      type = types.bool;
      default = false;
    };
    extraSessionVariables = mkOption {
      type = types.attrsOf types.str;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    home.sessionVariables = {
      XDG_SESSION_TYPE = "wayland";
      GDK_BACKEND = "wayland,x11";
      QT_QPA_PLATFORM = "wayland;xcb";
    }
    // cfg.extraSessionVariables;

    wayland.windowManager.hyprland = {
      enable = true;
      package = null;
      portalPackage = null;
      xwayland.enable = true;
      systemd.enable = false;
      settings.exec-once = [
        "hyprctl setcursor breeze_cursors ${builtins.toString config.my.display.cursorSize}"
      ];
      inherit extraConfig;
    };

    # Only pass scale env variables for XWayland apps.
    my.env = {
      QT_SCREEN_SCALE_FACTORS = builtins.toString cfg.scale;
      GDK_SCALE = builtins.toString cfg.scale;
      GDK_DPI_SCALE = builtins.toString (builtins.div 1 cfg.scale);
    };

    programs.wofi.enable = true;

    my.services.waybar = {
      enable = cfg.enableWaybar;
      inherit (cfg) zfsPoolName;
      inherit (cfg) monitors;
    };

    my.services.hyprpaper = {
      enable = cfg.enableHyprpaper;
      wallpapers = map (name: {
        monitor = cfg.monitors.${name}.output;
        path = cfg.monitors.${name}.wallpaper;
      }) (builtins.attrNames cfg.monitors);
    };

    my.services.hyprsunset.enable = cfg.enableHyprsunset;
  };
}
