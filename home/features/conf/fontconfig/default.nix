{ config, pkgs, ... }:

{
  fonts.fontconfig = { enable = true; };

  # home.packages = with pkgs; [
  #   noto-fonts
  #   noto-fonts-cjk-sans
  #   noto-fonts-cjk-serif
  #   noto-fonts-emoji
  #   inconsolata-lgc
  #   font-awesome_4
  #   dejavu_fonts
  #   (nerdfonts.override { fonts = [ "Noto" "InconsolataLGC" ]; })
  # ];
}
