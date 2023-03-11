{ config, pkgs, lib, hostname, ... }:

with lib; {
  imports = [
    # Essentials
    ../../../features/conf/ssh
    ../../../features/app/gpg
    # XSession related
    ../../../features/conf/xsession
    ../../../features/conf/xresources
    ../../../features/app/dunst
    ../../../features/app/unclutter
    ../../../features/app/wallpaper
    # Applications
    ../../../features/app/alacritty
    ../../../features/app/redshift
    ../../../features/app/rofi
    ../../../features/app/picom
    ../../../features/app/aria2
    ../../../features/app/fcitx5
    ../../../features/app/arandr
    ../../../features/app/copyq
    ../../../features/app/goldendict
    ../../../features/app/imwheel
    ../../../features/app/playctl
    ../../../features/app/flameshot
  ];

  home.packages = with pkgs; [
    keepassxc
    firefox
    google-chrome
    trash-cli
    jellyfin-media-player
    clementine
    gnome.nautilus
    ark
    unrar
    postman
    picard
    kate
    gwenview
    nodejs
    pandoc
    okular
    calibre
    libreoffice
    sonixd
    oxipng
    osdlyrics
  ];

  my.xsession.i3.enable = true;
  qt.enable = true;
  gtk.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  programs.zsh.shellAliases = {
    # Nix Home Manager
    snh = "switch-nix-home.sh";
    bnh = "build-nix-home.sh";
    # NixOS
    sno = "switch-nix-os.sh";
    bno = "build-nix-os.sh";
  };
  my.programs.emacs = {
    package = pkgs.myEmacs;
    enableSSHSpacemacsConfigRepo = true;
    startAfterXSession = true;
  };
  my.services.clipper.enable = true;
  my.services.syncthing.enable = true;
  my.programs.networkmanager-dmenu = {
    enable = true;
    settings = {
      dmenu.dmenu_command = "${config.programs.rofi.package}/bin/rofi -dmenu";
    };
  };

  xdg.desktopEntries = {
    sonixd = {
      name = "Sonixd";
      # Not sure why my font config causes tofu in this AppImage.
      exec =
        "env FONTCONFIG_FILE=${config.home.homeDirectory}/.config/fontconfig/conf.d/10-hm-fonts.conf ${pkgs.sonixd}/bin/sonixd";
      terminal = false;
      categories = [ "Player" ];
    };
  };
}
