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
            right = concatStringsSep " " [ "volume" ];
          };
          tray.position = "center";
          font = [ "Isevka8;2" "MaterialIcons:size=10" ];
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
          ramp-volume-0 = "";
          ramp-volume-1 = "";
          ramp-volume-2 = "";
          ramp-volume-3 = "";
          ramp-volume-4 = "";
        };
      };
      script =
        let polybarBinary = "${config.services.polybar.package}/bin/polybar";
        in ''
          for m in $(${polybarBinary} --list-monitors | ${pkgs.coreutils}/bin/cut -d":" -f1); do
              MONITOR=$m ${polybarBinary} top &
              ${pkgs.coreutils}/bin/sleep 1
          done
        '';
    };
  };
}

