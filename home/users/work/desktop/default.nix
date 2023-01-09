{ config, pkgs, lib, ... }:

with lib; {
  home.stateVersion = "23.05";

  home = rec {
    username = null;
    homeDirectory = null;
  };

  imports = [
    ../../../common/baseline.nix
    ../../../common/baseline-linux.nix
    # XSession related
    ../../../features/conf/xsession
    ../../../features/conf/xresources
    ../../../features/app/i3
    ../../../features/app/dunst
    ../../../features/app/unclutter
    ../../../features/app/wallpaper
    # Applications
    ../../../features/app/alacritty
    ../../../features/app/redshift
    ../../../features/app/rofi
    ../../../features/app/picom
    ../../../features/app/arandr
    ../../../features/app/copyq
    ../../../features/app/imwheel
    ../../../features/app/playctl
    ../../../features/app/flameshot
  ];

  home.packages = with pkgs; [
    keepassxc
    firefox-devedition-bin
    trash-cli
    clementine
    gnome.nautilus
    ark
    unrar
    kate
    gwenview
    okular
  ];

  qt.enable = true;
  gtk.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  my.programs.emacs = { package = pkgs.myEmacs; };
  my.services.clipper.enable = true;
  my.programs.networkmanager-dmenu = {
    enable = true;
    settings = {
      dmenu.dmenu_command = "${config.programs.rofi.package}/bin/rofi -dmenu";
    };
  };
}
