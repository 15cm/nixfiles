{ config, lib, pkgs, nixinfo, ... }:

with lib;
mkMerge [
  {
    home.packages = with pkgs; [
      gnome.gnome-font-viewer
      fontconfig
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-emoji
      font-awesome
      emacs-all-the-icons-fonts
      sarasa-gothic
      sarasa-gothic-nerdfont
      iosevka
      material-icons
    ];

    fonts.fontconfig.enable = true;
  }
  (mkIf (nixinfo.configName != "work@desktop") {
    xdg.configFile."fontconfig/conf.d/90-my-fonts.conf".source = ./fonts.conf;
  })
]
