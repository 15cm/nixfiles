{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.my.programs.hyprland;
  toLua = generators.toLua { };
  extraConfig = builtins.replaceStrings
    [
      "@appLauncherCommand@"
      "@brightnessDownCommand@"
      "@brightnessUpCommand@"
      "@clipboardCommand@"
      "@cursorSize@"
      "@dismissNotificationsCommand@"
      "@lockCommand@"
      "@monitorOne@"
      "@monitorTwo@"
      "@musicPlayer@"
      "@musicPlayerDesktopFileName@"
      "@muteCommand@"
      "@networkCommand@"
      "@restoreNotificationCommand@"
      "@scale@"
      "@screenshotCommand@"
      "@volumeDownCommand@"
      "@volumeUpCommand@"
      "@windowSwitcherCommand@"
    ]
    [
      (toLua cfg.appLauncherCommand)
      (toLua cfg.brightnessDownCommand)
      (toLua cfg.brightnessUpCommand)
      (toLua cfg.clipboardCommand)
      (toLua config.my.display.cursorSize)
      (toLua cfg.dismissNotificationsCommand)
      (toLua cfg.lockCommand)
      (toLua cfg.monitors.one.output)
      (toLua (if cfg.monitors ? two then cfg.monitors.two.output else null))
      (toLua cfg.musicPlayer)
      (toLua cfg.musicPlayerDesktopFileName)
      (toLua cfg.muteCommand)
      (toLua cfg.networkCommand)
      (toLua cfg.restoreNotificationCommand)
      (toLua (builtins.toJSON cfg.scale))
      (toLua cfg.screenshotCommand)
      (toLua cfg.volumeDownCommand)
      (toLua cfg.volumeUpCommand)
      (toLua cfg.windowSwitcherCommand)
    ]
    (builtins.readFile ./hyprland.lua);
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
    appLauncherCommand = mkOption {
      type = types.str;
      default = "wofi -iI --show drun";
    };
    windowSwitcherCommand = mkOption {
      type = types.str;
      default = "python ${./window_switcher.py}";
    };
    clipboardCommand = mkOption {
      type = types.str;
      default = "copyq toggle";
    };
    dismissNotificationsCommand = mkOption {
      type = types.str;
      default = "makoctl dismiss --all";
    };
    restoreNotificationCommand = mkOption {
      type = types.str;
      default = "makoctl restore";
    };
    networkCommand = mkOption {
      type = types.str;
      default = "networkmanager_dmenu";
    };
    screenshotCommand = mkOption {
      type = types.str;
      default = ''slurp | grim -g - - | wl-copy && wl-paste > "$HOME/Screenshots/$(date +'%Y-%m-%d-%H%M%S_grim.png')"'';
    };
    brightnessUpCommand = mkOption {
      type = types.str;
      default = "brightnessctl set 5%+";
    };
    brightnessDownCommand = mkOption {
      type = types.str;
      default = "brightnessctl set 5%-";
    };
    muteCommand = mkOption {
      type = types.str;
      default = "pactl set-sink-mute 0 toggle";
    };
    volumeUpCommand = mkOption {
      type = types.str;
      default = "pactl set-sink-mute 0 false && pactl set-sink-volume 0 +5%";
    };
    volumeDownCommand = mkOption {
      type = types.str;
      default = "pactl set-sink-volume 0 -5%";
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
    enableGammastep = mkOption {
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
      QT_QPA_PLATFORM = "wayland;xcb";
    }
    // cfg.extraSessionVariables;

    wayland.windowManager.hyprland = {
      enable = true;
      configType = "lua";
      package = null;
      portalPackage = null;
      xwayland.enable = true;
      systemd.enable = false;
      inherit extraConfig;
    };

    # Replace stale/generated Hyprland Lua files from previous activations.
    xdg.configFile."hypr/hyprland.lua".force = true;

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

    my.services.gammastep.enable = cfg.enableGammastep;
  };
}
