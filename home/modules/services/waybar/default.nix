{ pkgs, config, lib, mylib, ... }:

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
  };

  config = mkIf cfg.enable {
    programs.waybar = let
      hyprctlBinary =
        "${config.wayland.windowManager.hyprland.package}/bin/hyprctl";
    in {
      enable = true;
      systemd.enable = true;
      settings = {
        mainBar = {
          layer = "top";
          output = [ "DP-1" "DP-2" ];
          position = "top";
          height = 30;
          modules-left = [ "wlr/workspaces" ];
          modules-center = [ "clock#time" "clock#date" ];
          modules-right = [ "network" "network#speed" "cpu" "memory" ]
            ++ optionals (cfg.zfsRootPoolName != null) [ "custom/zfs" ]
            ++ [ "pulseaudio" "tray" ];
          "wlr/workspaces" = {
            format = "{icon}";
            all-outputs = true;
            on-click = "activate";
          };
          "tray" = { "spacing" = 10; };
          "clock#time" = {
            interval = 30;
            format = "{:%H:%M}  ";
          };
          "clock#date" = {
            interval = 30;
            format = "  {:%Y/%m/%d}";
            # It is not working at this point with hyprland. The on-click does not work.
            calendar = {
              mode = "year";
              mode-mon-col = 3;
              weeks-pos = "right";
              on-scroll = 1;
              on-click-right = "mode";
              format = {
                months = "<span color='#ffead3'><b>{}</b></span>";
                days = "<span color='#ecc6d9'><b>{}</b></span>";
                weeks = "<span color='#99ffdd'><b>W{}</b></span>";
                weekdays = "<span color='#ffcc66'><b>{}</b></span>";
                today = "<span color='#ff6699'><b><u>{}</u></b></span>";
              };
            };
            actions = {
              on-click-right = "mode";
              on-click-forward = "tz_up";
              on-click-backward = "tz_down";
              on-scroll-up = "shift_up";
              on-scroll-down = "shift_down";
            };
          };
          "cpu" = {
            interval = 10;
            format = "{usage}% ";
            min-length = 6;
            max-length = 8;
          };
          "memory" = {
            interval = 10;
            format = "{percentage}% ";
            min-length = 6;
            max-length = 10;
          };
          "pulseaudio" = {
            format = "{volume}% {icon}";
            format-bluetooth = "{volume}% {icon} ";
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
          "network" = {
            interval = 30;
            interface = "enp4s0";
            format = "{ifname}";
            format-wifi = "{essid} ({signalStrength}%) ";
            format-ethernet = "{ipaddr}/{cidr} ";
            format-disconnected = "";
            tooltip-format = "{ifname} via {gwaddr} ";
            tooltip-format-wifi = "{essid} ({signalStrength}%) ";
            tooltip-format-ethernet = "{ifname} via {gwaddr} ";
            tooltip-format-disconnected = "Disconnected";
            max-length = 50;
          };
          "network#speed" = {
            interval = 3;
            interface = "enp4s0";
            format = " {bandwidthDownBytes}  {bandwidthUpBytes}";
            min-length = 20;
            max-length = 20;
          };
          "custom/zfs" = {
            format = "{} ";
            exec = pkgs.writeShellScript "waybar-custom-zfs.sh" ''
              ${pkgs.zfs}/bin/zfs list -o available ${cfg.zfsRootPoolName} | ${pkgs.coreutils}/bin/tr -d "AVAIL\n" | ${pkgs.coreutils}/bin/tr -d " "
            '';
            interval = 30;
            min-length = 8;
            max-length = 10;
          };
        };
      };
      style = templateFile "waybar-style.css" templateData ./style.css.jinja;
    };
  };
}
