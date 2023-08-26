{ config, pkgs, lib, hostname, ... }:

let
  applyXwaylandEnvsToDesktopExec = exec:
    "env GDK_SCALE=${config.my.env.GDK_SCALE} env GDK_DPI_SCALE=${config.my.env.GDK_DPI_SCALE} ${exec}";
in with lib; {
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

    # Wayland env
    qt6.qtwayland
    qt5.qtwayland

    keepassxc
    firefox
    google-chrome
    trash-cli
    jellyfin-media-player
    clementine
    gnome.nautilus
    ark
    unrar
    insomnia
    picard
    kate
    gwenview
    nodejs
    pandoc
    okular
    calibre
    libreoffice
    feishin
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
    imagemagick
    dsf2flac
    neofetch
    cloc
    antimicrox
    unzip

    # Development
    postgresql
    nodePackages.js-beautify
    ccls
    ruby
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
    package = pkgs.emacs-unstable-pgtk;
    enableSSHSpacemacsConfigRepo = true;
    startAfterGraphicalSession = true;
  };
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

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
  my.services.network-manager-applet.enable = true;
  services.dunst.enable = true;
  my.services.gtklock = {
    enable = true;
    image =
      "${config.home.homeDirectory}/Pictures/lockscreens/yurucamp1@2x.png";
  };

  # Name the entry same as the entry that comes with the package to overwrite it.
  xdg.desktopEntries = {
    google-chrome = {
      name = "Google Chrome";
      exec = applyXwaylandEnvsToDesktopExec "google-chrome-stable"
        + " --ozone-platform=x11";
    };
    "com.github.iwalton3.jellyfin-media-player" = {
      name = "Jellyfin Media Player";
      exec = applyXwaylandEnvsToDesktopExec "jellyfinmediaplayer"
        + " --platform=xcb";
    };
    "transgui" = {
      icon = "transgui";
      name = "Transmission Remote GUI";
      exec = applyXwaylandEnvsToDesktopExec "transgui";
    };
    "insomnia" = {
      icon = "insomnia";
      name = "Insomnia";
      exec = "insomnia --ozone-platform=wayland --enable-wayland-ime";
    };
    "AriaNg" = {
      name = "AriaNg";
      exec = "firefox --new-window http://localhost:3001";
    };
    "feishin" = {
      name = "feishin";
      icon = "feishin";
      exec = applyXwaylandEnvsToDesktopExec "feishin"
        + " --disable-gpu-sandbox --ozone-platform=x11";
    };
    "calibre-gui" = {
      name = "Calibre";
      icon = "calibre-gui";
      exec = "env QT_IM_MODULE=wayland calibre --detach %U";
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
  programs.obs-studio.enable = true;

  my.programs.pythonDevTools.enable = true;
}
