{
  config,
  lib,
  pkgs,
  pkgsStable,
  ...
}:

let
  noctalia = lib.getExe config.programs.noctalia.package;
  setNoctaliaWallpapers = pkgs.writeShellScript "set-noctalia-wallpapers" ''
    set -eu

    set_wallpaper() {
      output="$(hyprctl monitors -j | ${lib.getExe pkgs.jq} -r --arg description "$1" \
        '.[] | select(.description == $description) | .name' | head -n 1)"
      if [ -n "$output" ]; then
        ${noctalia} msg wallpaper-set "$output" "$2"
      fi
    }

    ${lib.concatMapStringsSep "\n" (monitor: ''
      set_wallpaper \
        ${lib.escapeShellArg (lib.removePrefix "desc:" monitor.output)} \
        ${lib.escapeShellArg monitor.wallpaper}
    '') (lib.attrValues config.my.display.monitors)}
  '';
in
{
  home.stateVersion = "26.05";

  imports = [ ../common ];

  my.profiles.trusted.enable = true;

  my.essentials.gui.enable = true;
  my.essentials.gui.enablePolkitAgent = false;

  home.packages = with pkgs; [
    orca-ide
    pkgsStable.handbrake
  ];

  my.programs.hyprland = {
    enableWaybar = false;
    enableHyprpaper = false;
    enableGammastep = lib.mkForce false;
    appLauncherCommand = "${noctalia} msg panel-toggle launcher";
    windowSwitcherCommand = "${noctalia} msg window-switcher";
    clipboardCommand = "${noctalia} msg panel-toggle clipboard";
    dismissNotificationsCommand = "${noctalia} msg notification-clear-active";
    restoreNotificationCommand = "${noctalia} msg panel-toggle notifications";
    networkCommand = "${noctalia} msg panel-toggle control-center network";
    screenshotCommand = "${noctalia} msg screenshot-region";
    lockCommand = "${noctalia} msg session lock";
    brightnessUpCommand = "${noctalia} msg brightness-up";
    brightnessDownCommand = "${noctalia} msg brightness-down";
    muteCommand = "${noctalia} msg volume-mute";
    volumeUpCommand = "${noctalia} msg volume-up 5";
    volumeDownCommand = "${noctalia} msg volume-down 5";
    extraSessionVariables = {
      LIBVA_DRIVER_NAME = "nvidia";
      NVD_BACKEND = "direct";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      WLR_NO_HARDWARE_CURSORS = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };
  };

  wayland.windowManager.hyprland.settings.windowrule = [
    "focus_on_activate on, match:class orca"
  ];

  my.display.monitors = {
    one = {
      # https://wiki.hyprland.org/Configuring/Monitors/
      output = "desc:Dell Inc. DELL P2715Q 54KKD77P721L";
      wallpaper = "${config.home.homeDirectory}/Pictures/wallpapers/yande.re_455471_armor_fate_grand_order_heels_landscape_shielder_(fate_grand_order)_thighhighs_thkani@2x.png";
    };
    two = {
      output = "desc:Dell Inc. DELL U2718Q 4K8X78BC0DNL";
      wallpaper = "${config.home.homeDirectory}/Pictures/wallpapers/yande_128733_dress_kagome_keroq_minakami_yuki_smoking_subarashiki_hibi_thighhighs@2x.png";
    };
  };
  my.display.scale = 2.0;
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      shell = {
        font_family = "sans-serif";
        time_format = "{:%H:%M}";
        date_format = "%Y/%m/%d %a";
        polkit_agent = true;
        clipboard_enabled = true;
        clipboard_history_max_entries = 100;
        launcher.providers.windows = {
          prefix = "win";
          global = false;
        };
      };
      wallpaper = {
        enabled = true;
        directory = "${config.home.homeDirectory}/Pictures/wallpapers";
        default.path = config.my.display.monitors.one.wallpaper;
      };
      notification = {
        enable_daemon = true;
        show_app_name = true;
        show_actions = true;
      };
      lockscreen = {
        enabled = true;
        wallpaper = "${config.home.homeDirectory}/Pictures/lockscreens/yurucamp1@2x.png";
      };
      nightlight = {
        enabled = true;
        temperature_day = 4800;
        temperature_night = 3900;
      };
      location = {
        custom_schedule = true;
        sunrise = "06:00";
        sunset = "20:00";
      };
      bar.main = {
        position = "top";
        thickness = 36;
        margin_ends = 0;
        margin_edge = 0;
        radius = 0;
        start = [
          "cpu"
          "memory"
          "disk"
          "network"
          "network_rx"
          "network_tx"
          "volume"
        ];
        center = [ "workspaces" ];
        end = [
          "media"
          "clock"
          "tray"
          "notifications"
          "clipboard"
          "control-center"
          "session"
        ];
      };
      widget = {
        clock.format = "{:%H:%M %Y/%m/%d %a}";
        cpu = {
          type = "sysmon";
          stat = "cpu_usage";
          show_value = true;
        };
        memory = {
          type = "sysmon";
          stat = "ram_pct";
          show_value = true;
        };
        disk = {
          type = "sysmon";
          stat = "disk_free";
          path = "/";
          show_value = true;
        };
        network_rx = {
          type = "sysmon";
          stat = "net_rx";
          show_value = true;
        };
        network_tx = {
          type = "sysmon";
          stat = "net_tx";
          show_value = true;
        };
      };
      hooks.started = [ "${setNoctaliaWallpapers}" ];
    };
  };

  systemd.user.services = {
    fcitx5-daemon = {
      Unit = {
        After = lib.mkOverride 40 [ "graphical-session.target" ];
        PartOf = lib.mkOverride 40 [ "graphical-session.target" ];
      };
      Install.WantedBy = lib.mkOverride 40 [ "graphical-session.target" ];
    };
    syncthingtray = {
      Unit = {
        After = lib.mkOverride 40 [ "graphical-session.target" ];
        PartOf = lib.mkOverride 40 [ "graphical-session.target" ];
      };
      Install.WantedBy = lib.mkOverride 40 [ "graphical-session.target" ];
    };
  };

  programs.wofi.enable = lib.mkForce false;
  my.programs.networkmanager-dmenu.enable = lib.mkForce false;
  my.services.copyq.enable = lib.mkForce false;
  my.services.hyprlock.enable = lib.mkForce false;
  my.services.mako.enable = lib.mkForce false;
  my.services.network-manager-applet.enable = lib.mkForce false;
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };
}
