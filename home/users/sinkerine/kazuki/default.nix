args@{ config, pkgs, ... }:

let
  commonConfig = (import ../common/config.nix args);
  xresourcesArgs = {
    propertiesOverride = {
      "Xft.dpi" = 192;
      "Xcursor.size" = 48;
    };
  };
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
  nixpkgs = { inherit (commonConfig.nix.nixpkgs) overlays; };

  imports = [
    ../common
    # TODO: switch to the pkgs.emacsPgtkNativeComp when the nixfiles repo is stable. The Pgtk variant needs to compile from Emacs head and it takes a while.
    (import ../../../features/emacs
      (args // { withArgs.packageOverride = pkgs.emacsNativeComp; }))
    (import ../../../features/xresources (args // {
      withArgs = { inherit (xresourcesArgs) propertiesOverride; };
    }))
    ../../../features/alacritty
    ../../../features/keychain
    (import ../../../features/x-dotfiles
      (args // { withArgs.xprofile = xprofileArgs; }))
  ];
}
