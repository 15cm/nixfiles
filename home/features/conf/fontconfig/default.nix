{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    font-manager
    fontconfig
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-emoji
    font-awesome_4
    emacs-all-the-icons-fonts
    sarasa-gothic
    sarasa-gothic-nerdfont
    iosevka
  ];

  xdg.configFile."fontconfig/conf.d/90-my-fonts.conf".source = ./fonts.conf;
  # So that font manager can see the user installed fonts.
  home.file.".local/share/fonts".source = "${config.home.path}/share/fonts";
  fonts.fontconfig.enable = true;
}
