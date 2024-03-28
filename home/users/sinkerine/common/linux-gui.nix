{ config, pkgs, lib, hostname, mylib, ... }:

with lib;
let
  inherit (mylib)
    applyXwaylandEnvsToDesktopExec applyChromeFlagsToDesktopExec
    applyElectronFlagsToDesktopExec;
in {
  imports = [
    # Essentials
    ../../../features/conf/ssh
    ../../../features/app/gpg
    # XSession related. Needed by xWayland as well.
    ../../../features/conf/xresources
  ];

  home.packages = with pkgs; [
    # For tweaking XWayland config.
    xorg.xprop
    xorg.xrdb

    # Wayland env
    qt6.qtwayland
    qt5.qtwayland
    libsForQt5.qt5ct

    # Development
    postgresql
    nodePackages.js-beautify
    ccls
    ruby
    rust-analyzer
    pyright

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
    imagemagick
    dsf2flac
    neofetch
    cloc
    antimicrox
    unzip
    ueberzugpp
    sqlite
    kooha
    tremotesf
    goldendict-ng
    yt-dlp
    feishin-appimage
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
    inherit (config.my.display) monitors;
    inherit (config.my.display) scale;
    musicPlayer = "Feishin";
    musicPlayerDesktopFileName = "feishin.desktop";
  };

  # Only pass scale env variables for XWayland apps.
  my.env = {
    QT_SCREEN_SCALE_FACTORS = builtins.toString config.my.display.scale;
    GDK_SCALE = builtins.toString config.my.display.scale;
    GDK_DPI_SCALE = builtins.toString (builtins.div 1 config.my.display.scale);
  };

  programs.wofi.enable = true;
  my.services.waybar = {
    enable = true;
    zfsRootPoolName = "rpool";
    inherit (config.my.display) monitors;
  };
  my.services.hyprpaper = {
    enable = true;
    inherit (config.my.display) monitors;
  };

  qt = {
    enable = true;
    platformTheme = "kde";
    style.name = "breeze";
  };
  gtk = {
    enable = true;
    theme = {
      package = pkgs.breeze-gtk;
      name = "Breeze";
    };
    iconTheme = {
      package = pkgs.breeze-icons;
      name = "breeze";
    };
    cursorTheme = {
      package = pkgs.breeze-qt5;
      name = "breeze_cursors";
      size = config.my.display.cursorSize;
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
    snho = "switch-nix-home.sh --option substitute false";
    bnh = "build-nix-home.sh";
    # NixOS
    sno = "switch-nix-os.sh";
    snoo = "switch-nix-os.sh --option substitute false";
    bno = "build-nix-os.sh";
  };
  my.programs.emacs = {
    package = pkgs.emacs-unstable-pgtk;
    enableSSHConfigRepo = true;
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
  my.services.dunst.enable = true;
  my.services.gtklock = {
    enable = true;
    image =
      "${config.home.homeDirectory}/Pictures/lockscreens/yurucamp1@2x.png";
    extraArgs = [ "--no-input-inhibit" ];
  };

  # Name the entry same as the entry that comes with the package to overwrite it.
  xdg.desktopEntries = {
    google-chrome = {
      name = "Google Chrome";
      exec = applyChromeFlagsToDesktopExec "google-chrome-stable";
    };
    "com.github.iwalton3.jellyfin-media-player" = {
      name = "Jellyfin Media Player";
      exec = "jellyfinmediaplayer --platform=xcb";
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
    "io.github.xiaoyifang.goldendict_ng" = {
      name = "GoldenDict-ng";
      exec = "env GOLDENDICT_FORCE_WAYLAND=1 goldendict";
    };
    steam-fc-override = {
      name = "Steam (fc override)";
      exec =
        "env FONTCONFIG_FILE=${config.home.homeDirectory}/.config/fontconfig/conf.d/10-hm-fonts.conf steam";
      terminal = false;
    };
  };

  home.pointerCursor = {
    name = "breeze_cursors";
    package = pkgs.breeze-qt5;
    size = config.my.display.cursorSize;
    x11.enable = true;
    gtk.enable = true;
  };

  my.services.fcitx5 = {
    enable = true;
    enableWaylandEnv = true;
  };
  my.services.playerctld.enable = true;
  my.programs.alacritty.enable = true;
  my.services.gammastep.enable = true;

  my.programs.pythonDevTools.enable = true;

  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      Unit = {
        Description = "polkit-gnome-authentication-agent-1";
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart =
          "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };

  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [ wlrobs ];
  };
}
