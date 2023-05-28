{ config, pkgs, lib, hostname, ... }:

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
  ];

  home.packages = with pkgs; [
    # For tweaking XWayland config.
    xorg.xprop
    xorg.xrdb

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
    grim
    slurp
    xdg-utils
    khinsider
    transgui

    # Development
    pyright
    black
    isort
    python3Packages.docformatter
    ccls
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
    inherit (config.my.hardware) monitors;
  };
  programs.wofi.enable = true;
  my.services.waybar = {
    enable = true;
    zfsRootPoolName = "rpool";
    inherit (config.my.hardware) monitors;
  };
  my.services.hyprpaper = {
    enable = true;
    inherit (config.my.hardware) monitors;
  };

  qt.enable = true;
  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.gnome.gnome-themes-extra;
      name = "Adwaita";
    };
  };
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
  my.programs.fontconfig.enableGui = true;

  programs.zsh.shellAliases = {
    # Nix Home Manager
    snh = "switch-nix-home.sh";
    bnh = "build-nix-home.sh";
    # NixOS
    sno = "switch-nix-os.sh";
    bno = "build-nix-os.sh";
  };
  my.programs.emacs = {
    # With optimization, lsp-mode crashes emacs pgtk with seg fault, even with dontStrip = true. Has to compile with -O0.
    package = (pkgs.enableDebugging pkgs.emacsUnstablePgtk);
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
  my.services.gtklock = {
    enable = true;
    image =
      "${config.home.homeDirectory}/Pictures/lockscreens/yurucamp1@2x.png";
  };

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
    "transgui" = {
      icon = "transgui";
      name = "Transmission Remote GUI";
      exec =
        "env GDK_SCALE=${config.my.env.GDK_SCALE} env GDK_DPI_SCALE=${config.my.env.GDK_DPI_SCALE} XCURSOR_SIZE=${config.my.env.XCURSOR_SIZE} transgui";
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

  my.services.fcitx5.enable = true;
  my.services.playerctld.enable = true;
  my.programs.goldendict.enable = true;
}
