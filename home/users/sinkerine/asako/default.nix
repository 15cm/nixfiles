args@{ pkgs, ... }:

{
  home.stateVersion = "22.05";

  imports =
    [ ../common ../common/linux-gui.nix ../../../features/app/easyeffects ];

  home.packages = with pkgs; [ radeontop ];

  # Only pass scale env variables for XWayland apps.
  my.env = {
    QT_SCREEN_SCALE_FACTORS = "1.25";
    GDK_SCALE = "1.25";
    GDK_DPI_SCALE = "1";
    XCURSOR_SIZE = "36";
  };
}
