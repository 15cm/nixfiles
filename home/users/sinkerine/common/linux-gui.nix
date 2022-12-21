args@{ pkgs, lib, hostname, ... }:

with lib; {
  imports = [
    # Essentials
    ../../../features/conf/ssh
    # XSession related
    ../../../features/conf/xsession
    ../../../features/conf/xresources
    ../../../features/app/keychain
    ../../../features/app/i3
    ../../../features/app/dunst
    ../../../features/app/unclutter
    ../../../features/app/wallpaper
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
    ../../../features/app/flameshot
  ];

  home.packages = with pkgs; [
    keepassxc
    font-manager
    firefox
    google-chrome
    trash-cli
    jellyfin-media-player
    radeontop
    clementine
    gnome.nautilus
    ark
  ];

  qt.enable = true;
  gtk.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
}
