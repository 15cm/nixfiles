{ config, lib, pkgs, specialArgs, ... }:

with lib;
let
  inherit (specialArgs) theme;
  inherit (specialArgs.mylib) templateFile;
  templateData = {
    colorScheme = (if theme == "light" then "solarized-light" else "nord");
  };
  package = config.programs.powerline.package;
in {
  programs.powerline.enable = true;
  xdg.configFile."powerline/config.json".source =
    templateFile "powerline-config" templateData ./config.json.jinja;
  xdg.configFile."powerline/color.json".source = ./colors.json;
  xdg.configFile."powerline/colorschemes/nord.json".source =
    ./colorschemes/nord.json;
  xdg.configFile."powerline/colorschemes/solarized-light.json".source =
    ./colorschemes/solarized-light.json;
  xdg.configFile."powerline/colorschemes/shell/nord.json".source =
    ./colorschemes/shell/nord.json;
  xdg.configFile."powerline/colorschemes/shell/solarized-light.json".source =
    ./colorschemes/shell/solarized-light.json;
  xdg.configFile."powerline/colorschemes/tmux/nord.json".source =
    ./colorschemes/tmux/nord.json;
  xdg.configFile."powerline/colorschemes/tmux/solarized-light.json".source =
    ./colorschemes/tmux/solarized-light.json;
  xdg.configFile."powerline/themes/shell/default.json".source =
    ./themes/shell/default.json;
  xdg.configFile."powerline/themes/tmux/default.json".source =
    ./themes/tmux/default.json;
  programs.zsh.initExtra = ''
    # Powerline
    source ${package}/share/zsh/powerline.zsh
  '';
  programs.tmux.extraConfig = ''
    # Powerline
    source ${package}/share/tmux/powerline.conf
  '';
}
