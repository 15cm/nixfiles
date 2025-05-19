{ config, pkgs, ... }:

{
  home.stateVersion = "23.05";

  imports = [ ../common ../common/linux-gui.nix ];

  home.packages = with pkgs; [ radeontop ];

  my.display.monitors = {
    one = {
      output = "eDP-1";
      wallpaper =
        "${config.home.homeDirectory}/Pictures/wallpapers/yande_128733_dress_kagome_keroq_minakami_yuki_smoking_subarashiki_hibi_thighhighs@2x.png";
    };
  };
  my.display.scale = 1.25;
  my.services.hyprlock = {
    enable = true;
    image =
      "${config.home.homeDirectory}/Pictures/lockscreens/yurucamp1@2x.png";
  };
}
