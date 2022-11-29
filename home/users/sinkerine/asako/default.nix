args@{ specialArgs, config, pkgs, ... }:

let
  colorScheme = specialArgs.colorScheme;
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
  i3Args = {
    extraConfig = ''
      for_window [class="keepassxc" class="KeePassXC"] floating enable, resize set 800 400, move position center
      for_window [class="GoldenDict"] floating enable, move position center, resize set 800 400, move position center;
      for_window [class="^Anki$"] floating enable, resize set 600 300, move position center; mark anki
    '';
  };
  i3status-rust = {
    extraBlocks = [
      { block = "backlight"; }
      {

        block = "battery";
        driver = "upower";
        format = "{percentage} {time}";
        theme_overrides = (if colorScheme == "light" then {

          good_bg = "#fdf6e3"; # base3
          good_fg = "#586e75"; # base01
        } else {

          good_bg = "#2e3440"; # nord0
          good_fg = "#81a1c1"; # light blue
        });
      }
    ];
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
