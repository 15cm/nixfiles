{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    fontconfig
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-emoji
    inconsolata-lgc
    font-awesome_4
    (nerdfonts.override { fonts = [ "Noto" "InconsolataLGC" ]; })
  ];

  xdg.configFile."fontconfig/conf.d/90-my-fonts.conf".source = ./fonts.conf;
  home.file.".local/share/fonts".source = "${config.home.path}/share/fonts";
  fonts.fontconfig.enable = true;
}
