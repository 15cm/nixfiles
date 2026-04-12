{ config, pkgs, ... }:

{
  home.stateVersion = "23.05";

  imports = [
    ../common
    ../common/trusted.nix
  ];

  # Fallback monitor rule for Hyprland on this host.
  my.display.monitors.one = {
    output = "";
    wallpaper = "${config.home.homeDirectory}/Pictures/wallpapers/yande_128733_dress_kagome_keroq_minakami_yuki_smoking_subarashiki_hibi_thighhighs@2x.png";
  };

  my.programs.hyprland.extraSessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };
  my.programs.hyprland.enableWaybar = false;
  my.programs.hyprland.enableHyprpaper = false;
  my.programs.hyprland.zfsPoolName = "main";

  my.programs.baidupcs-go.enable = true;
}
