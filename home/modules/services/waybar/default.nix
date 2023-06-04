{ pkgs, config, lib, mylib, hostname, ... }:

with lib;
let
  cfg = config.my.services.waybar;
  inherit (mylib) templateFile;
  templateData = { };
in {
  options.my.services.waybar = {
    enable = mkEnableOption "waybar";
    zfsRootPoolName = mkOption {
      type = types.str;
      default = null;
    };
    monitors = mkOption {
      type = types.attrs;
      default = [ ];
    };
    networkInterface = mkOption {
      type = types.str;
      default = null;
    };
  };

  config = mkIf cfg.enable {
    programs.waybar = {
      enable = true;
      systemd.enable = true;
      settings = {
        mainBar = {
          layer = "top";
          output = (mapAttrsToList (name: value: value.output) cfg.monitors);
          position = "top";
          height = 30;
          modules-left = [ "cpu" "memory" ]
            ++ optionals (cfg.zfsRootPoolName != null) [ "custom/zfs" ]
            ++ [ "network" "network#speed" "pulseaudio" ]
            ++ optionals (hostname == "asako") [ "backlight" ];
          modules-center = [ "wlr/workspaces" "custom/isMaximized" ];
          modules-right = [ "mpris" ]
            ++ optionals (hostname == "asako") [ "battery" ]
            ++ [ "clock" "tray" ];
          "wlr/workspaces" = {
            format = "{icon}";
            all-outputs = true;
            on-click = "activate";
            sort-by-number = true;
          };
          "tray" = { "spacing" = 10; };
          "clock" = { format = "{: %H:%M  %Y/%m/%d %a}"; };
          "cpu" = {
            interval = 10;
            format = " {usage}%";
            min-length = 6;
            max-length = 8;
          };
          "memory" = {
            interval = 10;
            format = " {percentage}%";
            min-length = 6;
            max-length = 10;
          };
          "pulseaudio" = {
            format = "{volume}% {icon}";
            format-bluetooth = " {volume}% {icon}";
            format-muted = "";
            format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = [ "" "" ];
            };
            scroll-step = 1;
            on-click = "pavucontrol";
            ignored-sinks = [ "Easy Effects Sink" ];
          };
          "battery" = {
            interval = 60;
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{icon} {capacity}%";
            format-icons = [ "" "" "" "" "" ];
            min-length = 6;
            max-length = 25;
          };
          "backlight" = {
            # device = "intel_backlight";
            format = "{icon} {percent}%";
            format-icons = [ "" "" ];
            min-length = 6;
          };
          "network" = {
            interval = 30;
            interface = cfg.networkInterface;
            format = "{ifname}";
            format-wifi = " {essid} ({signalStrength}%)";
            format-ethernet = "{ipaddr}/{cidr} ";
            format-disconnected = "";
            tooltip-format = "{ifname} via {gwaddr} ";
            tooltip-format-wifi =
              " {essid} ({signalStrength}%) {ipaddr}/{cidr} via {gwaddr}";
            tooltip-format-ethernet = "{ifname} via {gwaddr} ";
            tooltip-format-disconnected = "Disconnected";
            max-length = 20;
          };
          "network#speed" = {
            interval = 3;
            interface = cfg.networkInterface;
            format = " {bandwidthDownBytes}  {bandwidthUpBytes}";
            min-length = 22;
            max-length = 25;
          };
          "custom/zfs" = {
            format = " {}";
            exec = pkgs.writeShellScript "waybar-custom-zfs.sh" ''
              zfs list -o available ${cfg.zfsRootPoolName} | tr -d "AVAIL\n" | tr -d " "
            '';
            interval = 30;
            min-length = 8;
            max-length = 10;
          };
          "custom/isMaximized" = {
            format = "{}";
            interval = 1;
            exec = pkgs.writeShellScript "waybar-custom-is-maximized.sh" ''
              result=$(hyprctl activewindow -j | jq ". | select(.fullscreen and .fullscreenMode == 1)")
              if [ -n "$result" ]; then
                echo "M"
              fi
            '';
          };
          "mpris" = {
            "format" = "{player_icon} {dynamic}";
            format-paused = "{status_icon} <i>{dynamic}</i>";
            player-icons = { "default" = ""; };
            status-icons = { "paused" = ""; };
            artist-len = 0;
            album-len = 0;
            title-len = if (hostname == "asako") then 20 else 40;
            dynamic-length = if (hostname == "asako") then 30 else 50;
          };
        };
      };
      style = templateFile "waybar-style.css" templateData ./style.css.jinja;
    };
  };
}
