{ config, lib, pkgs, state, mylib, ... }:

with lib;
let
  cfg = config.my.programs.powerline;
  inherit (state) theme;
  inherit (mylib) templateFile;
  templateData = {
    colorScheme = (if theme == "light" then "solarized-light" else "nord");
  };
in {
  options.my.programs.powerline = {
    enable = mkEnableOption "Powerline";
    package = mkOption {
      type = types.package;
      default = pkgs.powerline;
    };
  };
  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile = {
      "powerline/config.json".source =
        templateFile "powerline-config" templateData ./config.json.jinja;
      "powerline/color.json".source = ./colors.json;
      "powerline/colorschemes".source = ./colorschemes;
      "powerline/themes".source = ./themes;
    };
    programs.zsh.initContent = mkAfter ''
      # Powerline
      export POWERLINE_CONFIG_COMMAND=${cfg.package}/bin/powerline-config
      powerline-daemon -q
      source ${cfg.package}/share/zsh/powerline.zsh
    '';
    programs.tmux.extraConfig = ''
      # Powerline
      source ${cfg.package}/share/tmux/powerline.conf
    '';
  };
}
