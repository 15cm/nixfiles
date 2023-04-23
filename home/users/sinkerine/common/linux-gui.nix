{ config, pkgs, lib, hostname, ... }:

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
    dex
    krita
    unflac
    wl-clipboard
  ];

  programs.wofi.enable = true;
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = {
      mainBar = {
        layer = "top";
        output = [ "DP-1" "DP-2" ];
        position = "top";
        height = 30;
        modules-left = [ "wlr/workspaces" ];
        "wlr/workspaces" = {
          format = "{icon}";
          all-outputs = true;
        };
      };
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
  my.services.clipper.enable = true;
  my.services.syncthing.enable = true;
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

  wayland.windowManager.hyprland = {
    enable = true;
    nvidiaPatches = true;
    xwayland = {
      enable = true;
      hidpi = true;
    };
    extraConfig = ''
            env = LIBVA_DRIVER_NAME,nvidia
            env = XDG_SESSION_TYPE,wayland
            env = GBM_BACKEND,nvidia-drm
            env = __GLX_VENDOR_LIBRARY_NAME,nvidia
            env = WLR_NO_HARDWARE_CURSORS,1
            env = GDK_BACKEND,wayland,x11
            env = QT_QPA_PLATFORM,wayland;xcb
            env = GDK_SCALE,2
            env = QT_SCREEN_SCALE_FACTORS,2
            env = QT_AUTO_SCREEN_SCALE_FACTOR,1
            env = hyprctl setcursor Vanilla-DMZ 24

            monitor=DP-1, highres, auto, 2
            monitor=DP-2, highres, auto, 2
            exec-once = ${pkgs.xorg.xprop}/bin/xprop -root -f _XWAYLAND_GLOBAL_OUTPUT_SCALE 32c -set _XWAYLAND_GLOBAL_OUTPUT_SCALE 2
            exec-once = ${pkgs.xorg.xrdb}/bin/xrdb -merge ~/.Xresources

            wsbind=1,DP-1
            wsbind=2,DP-1
            wsbind=3,DP-1
            wsbind=4,DP-1
            wsbind=5,DP-1
            wsbind=6,DP-2
            wsbind=7,DP-2
            wsbind=8,DP-2
            wsbind=9,DP-2
            wsbind=0,DP-2
            workspace = DP-1, 1
            workspace = DP-2, 6

            animations {
                enabled = true

                # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

                bezier = myBezier, 0.05, 0.9, 0.1, 1.05

                animation = windows, 1, 7, myBezier
                animation = windowsOut, 1, 7, default, popin 80%
                animation = border, 1, 10, default
                animation = borderangle, 1, 8, default
                animation = fade, 1, 7, default
                animation = workspaces, 1, 6, default
            }

                          input {
            # Cursor focus will be detached from keyboard focus. Clicking on a window will move keyboard focus to that window.
                                follow_mouse = 2
                                repeat_rate = 20
                repeat_delay = 250
                          }

                          $mainMod = SUPER
                          bind = $mainMod, Q, killactive
                          bind = $mainMod, return, exec, alacritty
                          bind = $mainMod, D, exec, wofi --show drun

      bind = $mainMod, O, submap, open
      submap = open
      bind = , F, exec, firefox
      bind = , F, submap, reset
      bind = , D, exec, nautilus --new-window
      bind = , D, submap, reset
      bind = , S, exec, flameshot gui
      bind = , S, submap, reset
      bind = , escape, submap, reset
      submap = reset
                          general {
                              # See https://wiki.hyprland.org/Configuring/Variables/ for more

                              gaps_in = 5
                              gaps_out = 20
                              border_size = 4
                              col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
                              col.inactive_border = rgba(595959aa)
                              cursor_inactive_timeout = 300

                              layout = master
                          }

            master {
            new_is_master = false
            new_on_top = false
            }

            bind = $mainMod ALT, E, exit

            # Switch workspaces with mainMod + [0-9]
            bind = $mainMod, 1, workspace, 1
            bind = $mainMod, 2, workspace, 2
            bind = $mainMod, 3, workspace, 3
            bind = $mainMod, 4, workspace, 4
            bind = $mainMod, 5, workspace, 5
            bind = $mainMod, 6, workspace, 6
            bind = $mainMod, 7, workspace, 7
            bind = $mainMod, 8, workspace, 8
            bind = $mainMod, 9, workspace, 9
            bind = $mainMod, 0, workspace, 10

            # Move active window to a workspace with mainMod + SHIFT + [0-9]
            bind = $mainMod SHIFT, 1, movetoworkspace, 1
            bind = $mainMod SHIFT, 2, movetoworkspace, 2
            bind = $mainMod SHIFT, 3, movetoworkspace, 3
            bind = $mainMod SHIFT, 4, movetoworkspace, 4
            bind = $mainMod SHIFT, 5, movetoworkspace, 5
            bind = $mainMod SHIFT, 6, movetoworkspace, 6
            bind = $mainMod SHIFT, 7, movetoworkspace, 7
            bind = $mainMod SHIFT, 8, movetoworkspace, 8
            bind = $mainMod SHIFT, 9, movetoworkspace, 9
            bind = $mainMod SHIFT, 0, movetoworkspace, 10

            bind = $mainMod, j, layoutmsg, cyclenext
            bind = $mainMod, k, layoutmsg, cycleprev
            bind = $mainMod SHIFT, j, layoutmsg, swapnext
            bind = $mainMod SHIFT, k, layoutmsg, swapprev
            bind = $mainMod, h, layoutmsg, focusmaster
            bind = $mainMod SHIFT, h, layoutmsg, swapwithmaster master
            bind = $mainMod, n, focusmonitor, DP-1
            bind = $mainMod, m, focusmonitor, DP-2
            bind = $mainMod SHIFT, n, movewindow, mon:DP-1
            bind = $mainMod SHIFT, m, movewindow, mon:DP-2

            # Maximize
            bind = $mainMod, F, fullscreen, 1
            bind = $mainMod SHIFT, F, fullscreen, 0

            bind = $mainMod, mouse_up, workspace, e+1
            bind = $mainMod, mouse_down, workspace, e-1

            # Resize windows with mainMod + RMB and dragging
            bindm = $mainMod, mouse:273, resizewindow
    '';
  };
}
