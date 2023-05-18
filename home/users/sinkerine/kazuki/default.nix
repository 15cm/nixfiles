{ config, pkgs, ... }:

{
  home.stateVersion = "22.05";

  imports = [ ../common ../common/linux-gui.nix ../../../features/app/openrgb ];

  # Name the entry same as the entry that comes with the package to overwrite it.
  xdg.desktopEntries = {
    ryujinx = {
      name = "ryujinx (high priority)";
      exec = "nice -n -19 ryujinx %f";
      terminal = false;
    };
    vmware-workstation = {
      name = "VMware Workstation (high priority)";
      exec =
        "env GDK_SCALE=${config.my.env.GDK_SCALE} env GDK_DPI_SCALE=${config.my.env.GDK_DPI_SCALE} nice -n -19 vmware";
    };
  };

  # Only pass scale env variables for XWayland apps.
  my.env = {
    GDK_SCALE = "2";
    GDK_DPI_SCALE = "0.5";
    QT_SCREEN_SCALE_FACTORS = "2";
    XCURSOR_SIZE = "48";
  };

  # Host specific session variables.
  home.sessionVariables = {
    # Hyprland Nvidia
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
  };
}
