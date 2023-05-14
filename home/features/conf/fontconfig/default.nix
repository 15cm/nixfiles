{ config, lib, pkgs, nixinfo, ... }:

with lib;
mkMerge [
  {
    home.packages = with pkgs; [
      font-manager
      fontconfig
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-emoji
      emacs-all-the-icons-fonts
      sarasa-gothic
      sarasa-gothic-nerdfont
      iosevka
      iosevka-nerdfont
      material-design-icons
    ];

    # So that font manager can see the user installed fonts.
    home.file.".local/share/fonts".source = "${config.home.path}/share/fonts";
    fonts.fontconfig.enable = true;
  }
  (mkIf (nixinfo.configName != "work@desktop") {
    xdg.configFile."fontconfig/conf.d/90-my-fonts.conf".source = ./fonts.conf;
  })
]
