{ config, pkgs, lib, hostname, state, ... }:

with lib; {
  imports = [
    # Essentials
    ../../../features/conf/ssh
    ../../../features/app/gpg
    # XSession related. Needed by xWayland as well.
    ../../../features/conf/xresources
    # Applications
    ../../../features/app/alacritty
    ../../../features/app/aria2
    ../../../features/app/fcitx5
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

    # Development
    pyright
    black
    isort
    python3Packages.docformatter
  ];

  home.sessionVariables = {
    PATH = "${config.home.homeDirectory}/.nix-profile/bin:$PATH";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    # Hyprland
    XDG_SESSION_TYPE = "wayland";
    GDK_BACKEND = "wayland,x11";
    QT_QPA_PLATFORM = "wayland;xcb";
  };

  my.programs.hyprland = {
    enable = true;
    monitors = {
      one = "DP-1";
      two = "DP-2";
    };
    inherit (state) enableNightLightShader;
    nightLightTemperature = (if state.theme == "light" then 4000 else 3400);
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
    package = pkgs.emacsUnstablePgtk;
    enableSSHSpacemacsConfigRepo = true;
    startAfterGraphicalSession = true;
  };
  my.services.clipper = {
    enable = true;
    extraSettings = {
      executable = "/home/sinkerine/.nix-profile/bin/wl-copy";
      flags = "-n";
    };
  };
  my.services.copyq.enable = true;
  my.services.syncthing.enable = true;
  my.programs.networkmanager-dmenu = {
    enable = true;
    settings = {
      dmenu.dmenu_command = "${config.programs.wofi.package}/bin/wofi -dmenu";
    };
  };
  services.dunst.enable = true;
  my.services.swaylock.enable = true;

  # Name the entry same as the entry that comes with the package to overwrite it.
  xdg.desktopEntries = {
    sonixd = {
      name = "Sonixd";
      exec =
        "env GDK_SCALE=${config.my.env.GDK_SCALE} env GDK_DPI_SCALE=${config.my.env.GDK_DPI_SCALE} XCURSOR_SIZE=${config.my.env.XCURSOR_SIZE} ${pkgs.sonixd}/bin/sonixd --platform=xcb";
    };
    google-chrome = {
      name = "Google Chrome";
      exec =
        "env GDK_SCALE=${config.my.env.GDK_SCALE} env GDK_DPI_SCALE=${config.my.env.GDK_DPI_SCALE} XCURSOR_SIZE=${config.my.env.XCURSOR_SIZE} google-chrome-stable";
    };
    "com.github.iwalton3.jellyfin-media-player" = {
      name = "Jellyfin Media Player";
      exec =
        "env GDK_SCALE=${config.my.env.GDK_SCALE} env GDK_DPI_SCALE=${config.my.env.GDK_DPI_SCALE} XCURSOR_SIZE=${config.my.env.XCURSOR_SIZE} jellyfinmediaplayer --platform=xcb";
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
