{
  config,
  pkgs,
  lib,
  hostname,
  ...
}:

let
  cfg = config.my.essentials.gui;
in
{
  options.my.essentials.gui = {
    enable = lib.mkEnableOption "linux gui";
    headed = lib.mkEnableOption "headed linux gui";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        my.programs.hyprland = {
          enable = true;
          inherit (config.my.display) monitors scale;
          musicPlayer = "Feishin";
          musicPlayerDesktopFileName = "feishin.desktop";
        };
        home.sessionVariables = {
          PATH = "${config.home.homeDirectory}/.nix-profile/bin:$PATH";
          QT_AUTO_SCREEN_SCALE_FACTOR = "1";
        };
        xresources.properties = {
          "Xft.rgba" = "rgb";
          "Xft.antialias" = true;
          "Xft.hinting" = true;
          "Xft.lcdfilter" = "lcddefault";
        }
        // (
          if hostname == "asako" then
            {
              "Xft.dpi" = 120;
            }
          else
            {
              "Xft.dpi" = 192;
            }
        );
        my.programs.fontconfig.enableGui = true;
      }

      (lib.mkIf cfg.headed {
        home.packages = with pkgs; [
          # For tweaking XWayland config.
          xprop
          xrdb

          # Wayland env
          qt6.qtwayland
          # qt5.qtwayland
          # libsForQt5.qt5ct

          # Development
          gnumake
          postgresql
          ccls
          ruby
          rust-analyzer
          pyright

          keepassxc
          google-chrome
          trash-cli
          jellyfin-media-player
          clementine
          nemo
          kdePackages.ark
          unrar
          insomnia
          picard
          kdePackages.kate
          kdePackages.gwenview
          nodejs
          pandoc
          kdePackages.okular
          calibre
          libreoffice
          oxipng
          dex
          krita
          unflac
          wl-clipboard
          libnotify
          grim
          slurp
          xdg-utils
          khinsider
          imagemagick
          cloc
          antimicrox
          unzip
          sqlite
          kooha
          tremotesf
          goldendict-ng
          yt-dlp
          feishin
          qmk
          ffmpeg
          telegram-desktop
          kdePackages.kdenlive
          darktable
          webos-dev-manager
          wechat-uos
          discord
          prusa-slicer
          repomix
        ];

        my.programs.hyprland.enableHyprsunset = true;

        xdg.configFile."ssh/interactive.conf".source = ../../features/conf/ssh/interactive.conf;
        qt = {
          enable = true;
          platformTheme = {
            package = with pkgs; [
              kdePackages.plasma-integration
              kdePackages.systemsettings
            ];
          };
          style = {
            package = with pkgs; [ kdePackages.breeze ];
          };
        };
        xdg.configFile."kdeglobals".text = ''
          [DirSelect Dialog]
          DirSelectDialog Size=860,586

          [KFileDialog Settings]
          Allow Expansion=false
          Automatically select filename extension=true
          Breadcrumb Navigation=true
          Decoration position=2
          LocationCombo Completionmode=5
          PathCombo Completionmode=5
          Show Bookmarks=false
          Show Full Path=false
          Show Inline Previews=true
          Show Preview=false
          Show Speedbar=true
          Show hidden files=false
          Sort by=Name
          Sort directories first=true
          Sort hidden files last=false
          Sort reversed=false
          Speedbar Width=144
          View Style=DetailTree

          [KDE]
          SingleClick=false
        '';
        gtk = {
          enable = true;
          theme = {
            package = pkgs.kdePackages.breeze-gtk;
            name = "Breeze";
          };
          iconTheme = {
            package = pkgs.kdePackages.breeze-icons;
            name = "breeze";
          };
          gtk4.theme = config.gtk.theme;
        };
        xdg.userDirs = {
          enable = true;
          createDirectories = true;
          setSessionVariables = true;
        };
        my.services.gpg.enable = true;

        programs.zsh.shellAliases = {
          ssh = "ssh -F ~/.config/ssh/interactive.conf";
          # Nix Home Manager
          snh = "switch-nix-home.sh";
          snho = "switch-nix-home.sh --option substitute false";
          bnh = "build-nix-home.sh";
          # NixOS
          sno = "switch-nix-os.sh";
          snoo = "switch-nix-os.sh --option substitute false";
          bno = "build-nix-os.sh";
          webos-dev-manager = "NIXPKGS_ALLOW_UNFREE=1 nix run --impure github:nix-community/nixGL -- webos-dev-manager";
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
        my.programs.firefox = {
          enable = true;
          searchEngines = [
            {
              name = "GitHub";
              value = {
                urls = [
                  {
                    template = "https://github.com/search?q={searchTerms}&type=repositories";
                  }
                ];
                icon = "https://github.githubassets.com/favicons/favicon.svg";
                updateInterval = 24 * 60 * 60 * 1000; # every day
                definedAliases = [ "@gh" ];
              };
            }
            {
              name = "GitHub Code Search";
              value = {
                urls = [
                  {
                    template = "https://github.com/search?q={searchTerms}&type=code";
                  }
                ];
                icon = "https://github.githubassets.com/favicons/favicon.svg";
                updateInterval = 24 * 60 * 60 * 1000; # every day
                definedAliases = [ "@ghc" ];
              };
            }
            {
              name = "NixOS Packages";
              value = {
                urls = [
                  {
                    template = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}";
                  }
                ];
                icon = "https://search.nixos.org/favicon.png";
                updateInterval = 24 * 60 * 60 * 1000; # every day
                definedAliases = [ "@nixp" ];
              };
            }
            {
              name = "NixOS Options";
              value = {
                urls = [
                  {
                    template = "https://search.nixos.org/options?channel=unstable&query={searchTerms}";
                  }
                ];
                icon = "https://search.nixos.org/favicon.png";
                updateInterval = 24 * 60 * 60 * 1000; # every day
                definedAliases = [ "@nixo" ];
              };
            }
          ];
        };
      })
    ]
  );
}
