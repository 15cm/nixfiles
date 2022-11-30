{ config, lib, pkgs, state, mylib, ... }:

with lib;
let
  inherit (state) theme;
  inherit (mylib) templateFile;
  templateData = {
    colorScheme = (if theme == "light" then "solarized-light" else "nord");
  };
  package = config.programs.powerline.package;
in {
  programs.powerline.enable = true;
  xdg.configFile = {
    "powerline/config.json".source =
      templateFile "powerline-config" templateData ./config.json.jinja;
    "powerline/color.json".source = ./colors.json;
    "powerline/colorschemes".source = ./colorschemes;
    "powerline/themes".source = ./themes;
  };
  programs.zsh.initExtra = ''
    # Powerline
    source ${package}/share/zsh/powerline.zsh
    unset _POWERLINE_SAVE_WIDGET
  '';
  programs.tmux.extraConfig = ''
    # Powerline
    source ${package}/share/tmux/powerline.conf
  '';
}
