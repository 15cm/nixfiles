{ config, pkgs, ... }:

{
  home.stateVersion = "23.05";

  imports = [ ../common ../common/linux-gui.nix ];

  home.packages = with pkgs; [ radeontop ];

  # Only pass scale env variables for XWayland apps.
  my.env = {
    QT_SCREEN_SCALE_FACTORS = "1.25";
    GDK_SCALE = "1.25";
    GDK_DPI_SCALE = "1";
  };

  my.hardware.monitors = {
    one = {
      output = "eDP-1";
      wallpaper =
        "${config.home.homeDirectory}/Pictures/wallpapers/yande_128733_dress_kagome_keroq_minakami_yuki_smoking_subarashiki_hibi_thighhighs@2x.png";
    };
  };
  my.programs.hyprland.scale = 1.25;
  my.services.waybar.networkInterface = "wlp1s0";
  my.services.gammastep.enable = true;
  my.services.easyeffects.enable = true;
}
