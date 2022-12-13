{ config, pkgs, ... }:

{
  xdg.configFile."fontconfig/fonts.conf".source = ./fonts.conf;
}
