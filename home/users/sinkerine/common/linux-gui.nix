{ config, pkgs, lib, hostname, state, ... }:

with lib; {
  imports = [
    # Essentials
    ../../../features/conf/ssh
    ../../../features/app/gpg
    # XSession related
    ../../../features/conf/xresources
    ../../../features/app/dunst
    # Applications
    ../../../features/app/alacritty
    ../../../features/app/aria2
    ../../../features/app/fcitx5
    ../../../features/app/copyq
    ../../../features/app/goldendict
    ../../../features/app/playctl
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
    dex
    krita
    unflac
    wl-clipboard
    spectacle
    grim
    slurp
    # For tweaking XWayland config.
    xorg.xprop
    xorg.xrdb
  ];

  my.programs.hyprland = {
    enable = true;
    monitors = {
      one = "DP-1";
      two = "DP-2";
    };
    nightLightTemperature = (if state.enableNightLight then
      (if state.theme == "light" then 4000 else 3400)
    else
      null);
  };
  programs.wofi.enable = true;
  my.services.waybar = {
    enable = true;
    zfsRootPoolName = "rpool";
  };
  my.services.hyprpaper = {
    enable = true;
    monitorToWallPapers = {
      "DP-1" =
        "${config.home.homeDirectory}/Pictures/wallpapers/yande.re_455471_armor_fate_grand_order_heels_landscape_shielder_(fate_grand_order)_thighhighs_thkani@2x.png";
      "DP-2" =
        "${config.home.homeDirectory}/Pictures/wallpapers/yande_128733_dress_kagome_keroq_minakami_yuki_smoking_subarashiki_hibi_thighhighs@2x.png";
    };
  };

  # my.xsession.i3.enable = true;
  qt.enable = true;
  gtk.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
  my.programs.nixGL.enable = true;

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
  # my.services.clipper.enable = true;
  # my.services.syncthing.enable = true;
  my.programs.networkmanager-dmenu = {
    enable = true;
    settings = {
      dmenu.dmenu_command = "${config.programs.rofi.package}/bin/rofi -dmenu";
    };
  };

  # Name the entry same as the entry that comes with the package to overwrite it.
  xdg.desktopEntries = {
    sonixd = {
      name = "Sonixd";
      exec =
        "env GDK_DPI_SCALE=0.5 XCURSOR_SIZE=48 ${pkgs.sonixd}/bin/sonixd --platform=xcb";
    };
    google-chrome = {
      name = "Google Chrome";
      exec = "env GDK_DPI_SCALE=0.5 XCURSOR_SIZE=48 google-chrome-stable";
    };
    "com.github.iwalton3.jellyfin-media-player" = {
      name = "Jellyfin Media Player";
      exec =
        "env GDK_DPI_SCALE=0.5 XCURSOR_SIZE=48 jellyfinmediaplayer --platform=xcb";
    };
  };

  home.pointerCursor = {
    name = "Vanilla-DMZ";
    package = pkgs.vanilla-dmz;
    size = 24;
    x11.enable = true;
    gtk.enable = true;
  };
  home.file.".icons/default".source =
    "${pkgs.vanilla-dmz}/share/icons/Vanilla-DMZ";
}
