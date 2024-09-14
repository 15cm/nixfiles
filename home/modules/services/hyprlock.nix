{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.services.hyprlock;
in {
  options.my.services.hyprlock = {
    enable = mkEnableOption "hyprlock";
    package = mkOption {
      type = types.package;
      default = pkgs.hyprlock;
      defaultText = literalExpression "pkgs.hyprlock";
      description = "The hyprlock package to install.";
    };
    image = mkOption {
      type = with types; nullOr str;
      default = null;
    };
  };

  config = mkIf cfg.enable (mkMerge [{
    home.packages = [ cfg.package ];
    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          disable_loading_bar = true;
          grace = 3;
          hide_cursor = true;
          no_fade_in = false;
        };

        background = [{
          path = cfg.image;
          blur_passes = 1;
          blur_size = 1;
        }];

        input-field = [{
          size = "200, 50";
          position = "0, -80";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(202, 211, 245)";
          inner_color = "rgb(91, 96, 120)";
          outer_color = "rgb(24, 25, 38)";
          outline_thickness = 5;
          placeholder_text = ''<span foreground="##cad3f5">Password...</span>'';
          shadow_passes = 2;
          rounding = -1; # -1 means complete rounding (circle/oval)
          check_color = "rgb(204, 136, 34)";
          fail_color =
            "rgb(204, 34, 34)"; # if authentication failed, changes outer_color and fail message color
          fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>"; # can be set to empty
          fail_timeout =
            2000; # milliseconds before fail_text and fail_color disappears
          fail_transition =
            300; # transition time in ms between normal outer_color and fail_color
          capslock_color = -1;
          numlock_color = -1;
          bothlock_color =
            -1; # when both locks are active. -1 means don't change outer color (same for above)
          invert_numlock = false; # change color if numlock is off
          swap_font_color = false; # see below
        }];
        label = [{
          monitor = "";
          text = "$TIME";
          # center/right or any value for default left. multi-line text alignment inside label container
          text_align = "center";
          color = "rgba(200, 200, 200, 1.0)";
          font_size = 25;
          font_family = "Noto Sans";
          rotate = 0; # degrees, counter-clockwise
          position = "0, 80";
          halign = "center";
          valign = "center";
        }];
      };
    };
    systemd.user.services.hyprlock = {
      Unit = { Description = "Hyprlock"; };
      Service = {
        ExecStart =
          concatStringsSep " " [ "${cfg.package}/bin/hyprlock" "--immediate" ];
        Type = "simple";
      };
    };
  }]);
}
