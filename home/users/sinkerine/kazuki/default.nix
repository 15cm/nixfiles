args@{ config, pkgs, ... }:

let
  xresourcesArgs = { propertiesOverride = { "Xft.dpi" = 192; "Xcursor.size" = 48;}; };
  xprofileArgs = {
    extraConfig = ''
      # QT
      export QT_SCREEN_SCALE_FACTORS=2

      # GTK
      export GDK_SCALE=2
      export GDK_DPI_SCALE=0.5

      # Alacritty
      export WINIT_HIDPI_FACTOR=2
    '';
  };
in {
  home.stateVersion = "22.05";
  imports = [
    ../common
    (import ../../../features/xresources (args // {
      withArgs = { inherit (xresourcesArgs) propertiesOverride; };
    }))
    ../../../features/alacritty
    ../../../features/keychain
    (import ../../../features/x-dotfiles
      (args // { withArgs.xprofile = xprofileArgs; }))
  ];
}
