{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.services.polybar;
in {
  options.my.services.polybar = { enable = mkEnableOption "polybar"; };
  config = mkIf cfg.enable {
    services.polybar = {
      enable = true;
      package = pkgs.polybar.override {
        i3Support = true;
        pulseSupport = true;
      };
      # The theme is a fork of https://github.com/adi1090x/polybar-themes/tree/master/bitmap/material
      settings = let
        color = {
          background = "#1F1F1F";
          foreground = "#FFFFFF";
          foreground-alt = "#8F8F8F";
          module-fg = "#1F1F1F";
          primary = "#ffb300";
          secondary = "#E53935";
          alternate = "#7cb342";
          warning = "#ff6700";
          alert = "#e60053";
        };
      in {

        "bar/top" = {
          monitor = "\${env:MONITOR}";
          # Values in the X resources db can be referenced using:
          # ${xrdb:KEY:fallback_value}
          dpi = "\${xrdb:Xft.dpi:-1}";
          tray-maxsize = 32;
          width = "100%";
          height = "3%";
          modules = {
            left = "i3";
            right = concatStringsSep " " [
              "wired-network"
              "memory"
              "cpu"
              "filesystem"
              "volume"
              "date"
            ];
          };
          tray.position = "right";
          font = [
            "Iosevka:size=10;2"
            "MaterialDesignIcons:size=12;2"
            "IosevkaNerdFont:size=12;2"
          ];
          padding = 1;
          module = {
            margin = 1;
            padding = 1;
          };
        };

        "module/i3" = {
          type = "internal/i3";
          label-mode = "%mode%";
          label-mode-padding = "2";
          label-mode-background = "#e60053";

          label-focused = "%index%";
          label-focused-foreground = "#ffffff";
          label-focused-background = "#3f3f3f";
          label-focused-underline = "#fba922";
          label-focused-padding = "4";

          label-unfocused = "%index%";
          label-unfocused-padding = "4";
        };

        "module/volume" = {
          type = "internal/pulseaudio";
          format = {
            # Available tags:
            #   <label-volume> (default)
            #   <ramp-volume>
            #   <bar-volume>
            volume = {
              text = "<ramp-volume> <label-volume>";
              background = color.background;
              padding = 1;
            };
            # Available tags:
            #   <label-muted> (default)
            #   <ramp-volume>
            #   <bar-volume>
            label = {
              volume = "%percentage%";
              muted = {
                text = "Muted";
                foreground = color.foreground;
                padding = 1;
              };
            };
          };
          # Only applies if <ramp-volume> is used
          ramp-volume-0 = "󰸈";
          ramp-volume-1 = "󰕾";
          ramp-volume-2 = "󰕾";
          ramp-volume-3 = "󰕾";
          ramp-volume-4 = "󰕾";
        };

        "module/date" = {
          type = "internal/date";
          # See "http://en.cppreference.com/w/cpp/io/manip/put_time" for details on how to format the date string
          # NOTE: if you want to use syntax tags here you need to use %%{...}
          date = "%Y-%m-%d %a";
          time = "%H:%M";
          # Available tags:
          # <label> (default)
          format = "<label>";
          # Available tokens:
          #   %date%
          #   %time%
          # Default: %date%
          label = "󰅐 %time% 󰃶 %date%";
        };

        "module/cpu" = {
          type = "internal/cpu";
          # Available tags:
          #   <label> (default)
          #   <bar-load>
          #   <ramp-load>
          #   <ramp-coreload>
          # format = <label> <ramp-coreload>
          format = {
            text = "<label>";
            prefix = "󰍛";
          };
          # Available tokens:
          #   %percentage% (default) - total cpu load averaged over all cores
          #   %percentage-sum% - Cumulative load on all cores
          #   %percentage-cores% - load percentage for each core
          #   %percentage-core[1-9]% - load percentage for specific core
          label = " %percentage:3%%";
        };

        "module/memory" = {
          type = "internal/memory";
          # Available tags:
          #   <label> (default)
          #   <bar-used>
          #   <bar-free>
          #   <ramp-used>
          #   <ramp-free>
          #   <bar-swap-used>
          #   <bar-swap-free>
          #   <ramp-swap-used>
          #   <ramp-swap-free>
          format = "<label> <bar-used>";
          format-prefix = "󰘚";
          bar.used = {
            indicator = "";
            width = 10;
            foreground-0 = "#55aa55";
            foreground-1 = "#557755";
            foreground-2 = "#f5a70a";
            foreground-3 = "#ff5555";
            fill = "▐";
            empty = {
              text = "▐";
              foreground = "#444444";
            };
          };
          # Available tokens:
          #   %percentage_used% (default)
          #   %percentage_free%
          #   %gb_used%
          #   %gb_free%
          #   %gb_total%
          #   %mb_used%
          #   %mb_free%
          #   %mb_total%
          #   %percentage_swap_used%
          #   %percentage_swap_free%
          #   %mb_swap_total%
          #   %mb_swap_free%
          #   %mb_swap_used%
          #   %gb_swap_total%
          #   %gb_swap_free%
          #   %gb_swap_used%
          label = " %gb_used:5%/%gb_total:5%";
        };

        "module/filesystem" = let
          zfsBinary = "${pkgs.zfs}/bin/zfs";
          trBinary = "${pkgs.coreutils}/bin/tr";
          pool = "rpool";
        in {
          type = "custom/script";
          interval = 30;
          format = "<label>";
          exec = pkgs.writeShellScript "polybar-zsh.sh" ''
            pool_available=$(${zfsBinary} list -o available ${pool} | ${trBinary} -d "AVAIL\n" | ${trBinary} -d " ")
            echo "󰋊 $pool_available"
          '';
        };

        "module/wired-network" = {
          type = "internal/network";
          interface.type = "wired";
          speed.unit = "B/s";
          format = {
            # Available tags:
            #   <label-connected> (default)
            #   <ramp-signal>
            connected = "<label-connected>";
            disconnected = "<label-disconnected>";
          };
          label = {
            connected = {
              text = "󰌘 %local_ip% 󰛴 %downspeed:8% 󰛶 %upspeed:8%";
              foreground = "${color.foreground}";
            };
            disconnected = {
              text = "󰌙";
              foreground = "${color.primary}";
            };
          };
        };

      };

      script =
        let polybarBinary = "${config.services.polybar.package}/bin/polybar";
        in ''
          for m in $(${polybarBinary} --list-monitors | ${pkgs.coreutils}/bin/cut -d":" -f1); do
              MONITOR=$m ${polybarBinary} top &
              ${pkgs.coreutils}/bin/sleep 3
          done
        '';
    };
  };
}

