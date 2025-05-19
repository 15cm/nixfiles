{ config, pkgs, state, mylib, hostname, ... }:

let inherit (mylib) applyXwaylandEnvsToDesktopExec;
in {
  home.stateVersion = "23.05";

  imports = [ ../common ../common/linux-gui.nix ];

  home.packages = with pkgs; [ handbrake ];

  # Name the entry same as the entry that comes with the package to overwrite it.
  xdg.desktopEntries = {
    ryujinx = {
      name = "Ryujinx (high priority)";
      exec = "nice -n -19 ryujinx %f";
      terminal = false;
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

  # Host specific session variables.
  home.sessionVariables = {
    # Hyprland Nvidia
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
      wallpaper =
        "${config.home.homeDirectory}/Pictures/wallpapers/yande.re_455471_armor_fate_grand_order_heels_landscape_shielder_(fate_grand_order)_thighhighs_thkani@2x.png";
    };
    two = {
      output = "desc:Dell Inc. DELL U2718Q 4K8X78BC0DNL";
      wallpaper =
        "${config.home.homeDirectory}/Pictures/wallpapers/yande_128733_dress_kagome_keroq_minakami_yuki_smoking_subarashiki_hibi_thighhighs@2x.png";
    };
  };
  my.display.scale = 2.0;
  my.services.hyprlock = {
    enable = true;
    image =
      "${config.home.homeDirectory}/Pictures/lockscreens/yurucamp1@2x.png";
  };

  my.programs.jetbrains = {
    enable = true;
    enableAndroidStudio = true;
  };
}
