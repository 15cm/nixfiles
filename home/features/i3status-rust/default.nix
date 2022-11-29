{ specialArgs, ... }:
let
  inherit (specialArgs.mylib) templateFile;
  templateData = rec {
    inherit (specialArgs) hostname theme;
    colorScheme = (if theme == "light" then "solarized-light" else "nord-dark");
  };
in {
  programs.i3status-rust = {
    enable = true;
    bars = { default = { }; };
    settings = {
      icons = "awesome";

      theme = {
        name =
          (if colorScheme == "light" then "solarized-light" else "nord-dark");
        overrides.separator = "";
      };
      block = [
        {
          block = "networkmanager";
          interface_name_exclude = [ "br-[0-9a-f]{12}" "dockerd+" ];
          interface_name_include = [ ];
          theme_overrides = (if colorScheme == "light" then {
            good_bg = "#fdf6e3"; # base3
            good_fg = "#586e75"; # base01
          } else {
            good_bg = "#2e3440"; # nord0
            good_fg = "#81a1c1"; # light blue
          });
        }
        {
          block = "net";
          format = "{speed_down;K} {graph_down;K} {speed_up;K} {graph_up;K}";
          interval = 5;
          icons_overrides = {
            net_wired = "";
            net_wireless = "";
            net_vpn = "";
            net_loopback = "";
          };
        }
        {
          block = "memory";
          display_type = "memory";
          format_mem = "{mem_used_percents}";
          format_swap = "{swap_used_percents}";
        }
        {
          block = "cpu";
          interval = 3;
        }
        {
          block = "disk_space";
          path = "/";
          alias = "/";
          info_type = "available";
          unit = "GB";
          interval = 1800;
          warning = 20.0;
          alert = 10.0;
          format = "{icon} {available}";
        }
        { block = "sound"; }
        {
          block = "time";
          interval = 60;
          format = "%a %m/%d/%Y %R";
        }
      ] ++ withArgs.extraBlocks;
    };
  };
}
