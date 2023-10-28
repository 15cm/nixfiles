{ config, pkgs, state, ... }:

{
  home.stateVersion = "23.05";

  imports = [ ../common ../common/linux-gui.nix ../../../features/app/openrgb ];

  home.packages = with pkgs; [ handbrake ];

  # Name the entry same as the entry that comes with the package to overwrite it.
  xdg.desktopEntries = {
    ryujinx = {
      name = "Ryujinx (high priority)";
      exec = "nice -n -19 ryujinx %f";
      terminal = false;
    };
    vmware-workstation = {
      name = "VMware Workstation (high priority)";
      exec =
        "env GDK_SCALE=${config.my.env.GDK_SCALE} GDK_DPI_SCALE=${config.my.env.GDK_DPI_SCALE} nice -n -19 vmware";
    };
    steam-fc-override = {
      name = "Steam (fc override)";
      exec =
        "env FONTCONFIG_FILE=${config.home.homeDirectory}/.config/fontconfig/conf.d/10-hm-fonts.conf steam";
      terminal = false;
    };
  };

  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      Unit = {
        Description = "polkit-gnome-authentication-agent-1";
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart =
          "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };

  # Only pass scale env variables for XWayland apps.
  my.env = {
    GDK_SCALE = "2";
    GDK_DPI_SCALE = "0.5";
    QT_SCREEN_SCALE_FACTORS = "2";
  };

  # Host specific session variables.
  home.sessionVariables = {
    # Hyprland Nvidia
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  my.hardware.monitors = {
    one = {
      output = "DP-1";
      wallpaper =
        "${config.home.homeDirectory}/Pictures/wallpapers/yande.re_455471_armor_fate_grand_order_heels_landscape_shielder_(fate_grand_order)_thighhighs_thkani@2x.png";
    };
    two = {
      output = "DP-2";
      wallpaper =
        "${config.home.homeDirectory}/Pictures/wallpapers/yande_128733_dress_kagome_keroq_minakami_yuki_smoking_subarashiki_hibi_thighhighs@2x.png";
    };
  };

  my.programs.hyprland = {
    inherit (config.my.hardware) monitors;
    scale = 2.0;

  };
  my.services.waybar.networkInterface = "enp4s0";
  my.programs.yazi.scale = 2.0;
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [ wlrobs ];
  };
  my.services.gammastep.enable = true;
}
