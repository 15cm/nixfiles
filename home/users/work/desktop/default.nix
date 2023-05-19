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
    sonixd
  ];

  xresources.properties."Xft.dpi" = mkForce 120;
  xresources.properties."Xcursor.size" = mkForce 32;

  programs.zsh.shellAliases = {
    # Nix Home Manager
    snh = "switch-nix-home.sh";
    # NixOS
    sno = "switch-nix-os.sh";
  };

  my.xsession.i3 = {
    enable = true;
    musicPlayer = "Sonixd";
    monitors = {
      one = "DisplayPort-1";
      two = "DisplayPort-3";
    };
  };
  qt.enable = true;
  gtk.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  my.programs.emacs = {
    package = pkgs.emacsUnstable;
    # Fixes non-standard home directory.
    # https://emacs.stackexchange.com/questions/34022/error-initialization-user-has-no-home-directory
    extraOptions = [ "--user" "''" ];
  };
  my.services.clipper.enable = true;
  services.dunst.enable = true;
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
      exec = "${pkgs.sonixd}/bin/sonixd";
      terminal = false;
      categories = [ "Player" ];
    };
  };

  my.programs.nixGL.enable = true;
  my.programs.hmSwitch.useImpure = true;
}
