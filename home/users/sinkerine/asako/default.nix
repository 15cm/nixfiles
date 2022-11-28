args@{ config, pkgs, ... }:

let
  xresourcesArgs = {
    propertiesOverride = {
      "Xft.dpi" = 120;
      "Xcursor.size" = 30;
    };
  };
  xprofileArgs = {
    extraConfig = ''
      # QT
      export QT_SCREEN_SCALE_FACTORS=1.25

      # GTK
      export GDK_SCALE=1.25
      export GDK_DPI_SCALE=0.8

      # Alacritty
      export WINIT_HIDPI_FACTOR=1.25

      # Disable trackpad
      xinput disable "ELAN06A0:00 04F3:3231 Touchpad"
      # TrackPoint flat acceleration 
      xinput set-prop "TPPS/2 Elan TrackPoint" "libinput Accel Profile Enabled" 0, 1
    '';
  };
in {
  home.stateVersion = "22.05";
  nixpkgs = { inherit (commonConfig.nix.nixpkgs) overlays; };

  imports = [
    ../common
    # TODO: switch to the pkgs.emacsPgtkNativeComp when the nixfiles repo is stable. The Pgtk variant needs to compile from Emacs head and it takes a while.
    (import ../../../features/emacs
      (args // { withArgs.packageOverride = pkgs.emacsPgtkNativeComp; }))
    (import ../../../features/xresources (args // {
      withArgs = { inherit (xresourcesArgs) propertiesOverride; };
    }))
    ../../../features/alacritty
    ../../../features/keychain
    (import ../../../features/x-dotfiles
      (args // { withArgs.xprofile = xprofileArgs; }))
  ];

}
