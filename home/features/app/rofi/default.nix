{ pkgs, mylib, state, ... }:

let
  inherit (mylib) templateFile;
  templateData = { inherit (state) theme; };
in {
  home.packages = [ pkgs.rofi pkgs.rofi-emoji ];

  xdg.configFile = {
    "rofi/config.rasi".source =
      templateFile "rofi-config" templateData ./config.rasi.jinja;
    "rofi/nord.rasi".source = ./nord.rasi;
    "rofi/gruvbox-light-soft.rasi".source = ./gruvbox-light-soft.rasi;
    "rofi/gruvbox-common.inc.rasi".source = ./gruvbox-common.inc.rasi;
  };
}
