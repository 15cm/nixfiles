{ config, pkgs, ... }:

{
  # home..source = ./fonts.conf;
  fonts.fontconfig = { enable = true; };

  home.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-emoji
    inconsolata-lgc
    (nerdfonts.override { fonts = [ "Noto" "InconsolataLGC" ]; })
  ];
}
