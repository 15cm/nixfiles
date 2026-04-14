{ config, pkgs, ... }:

{
  home.stateVersion = "23.05";

  imports = [
    ../common
    ../common/trusted.nix
  ];

  my.essentials.gui.enable = true;

  home.packages = with pkgs; [
    handbrake
  ];

  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      Unit = {
        Description = "polkit-gnome-authentication-agent-1";
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };

  my.programs.hyprland.extraSessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  my.display.monitors = {
    one = {
      # https://wiki.hyprland.org/Configuring/Monitors/
      output = "desc:Dell Inc. DELL P2715Q 54KKD77P721L";
      wallpaper = "${config.home.homeDirectory}/Pictures/wallpapers/yande.re_455471_armor_fate_grand_order_heels_landscape_shielder_(fate_grand_order)_thighhighs_thkani@2x.png";
    };
    two = {
      output = "desc:Dell Inc. DELL U2718Q 4K8X78BC0DNL";
      wallpaper = "${config.home.homeDirectory}/Pictures/wallpapers/yande_128733_dress_kagome_keroq_minakami_yuki_smoking_subarashiki_hibi_thighhighs@2x.png";
    };
  };
  my.display.scale = 2.0;
  my.services.hyprlock = {
    enable = true;
    image = "${config.home.homeDirectory}/Pictures/lockscreens/yurucamp1@2x.png";
  };
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };
}
