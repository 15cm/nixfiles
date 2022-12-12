args@{ pkgs, lib, hostname, ... }:

with lib; {
  imports = [
    # Essentials
    (import ../../../features/app/emacs
      (args // { withArgs.packageOverride = pkgs.emacsUnstable; }))
    ../../../features/conf/ssh
    # XSession related
    ../../../features/conf/xsession
    ../../../features/conf/xresources
    ../../../features/app/keychain
    ../../../features/conf/fontconfig
    ../../../features/app/i3
    # Applications
    ../../../features/app/alacritty
    ../../../features/conf/mpv
    ../../../features/app/redshift
    ../../../features/app/rofi
    ../../../features/app/picom
    ../../../features/app/aria2
    ../../../features/app/fcitx5
    ../../../features/app/arandr
    ../../../features/app/copyq
    ../../../features/app/goldendict
    ../../../features/app/imwheel
    ../../../features/app/nm-applet
    ../../../features/app/playctl
    ../../../features/app/syncthing
    ../../../features/app/unclutter
    ../../../features/app/wallpaper
  ];

  home.packages = with pkgs; [ keepassxc font-manager firefox chromium ];
}
