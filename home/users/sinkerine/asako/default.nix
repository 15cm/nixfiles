{ config, pkgs, ... }:

{
  home.stateVersion = "26.05";

  imports = [ ../common ];

  my.profiles.trusted.enable = true;

  my.essentials.gui.enable = true;

  home.packages = with pkgs; [
    orca-ide
    radeontop
  ];

  wayland.windowManager.hyprland.settings.windowrule = [
    "focus_on_activate on, match:class orca"
  ];

  my.display.monitors = {
    one = {
      output = "eDP-1";
      wallpaper = "${config.home.homeDirectory}/Pictures/wallpapers/yande_128733_dress_kagome_keroq_minakami_yuki_smoking_subarashiki_hibi_thighhighs@2x.png";
    };
  };
  my.display.scale = 1.25;
  my.programs.foot.fontSize = 8;
}
