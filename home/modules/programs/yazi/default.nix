{ config, lib, pkgs, state, mylib, ... }:

with lib;
let
  cfg = config.my.programs.yazi;
  inherit (mylib) templateFile;
in {
  options.my.programs.yazi = {
    enable = mkEnableOption "Yazi";
    package = mkOption {
      type = types.package;
      default = pkgs.yazi;
    };
    scale = mkOption {
      type = types.float;
      default = 1.0;
    };
  };
  config = mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      inherit (cfg) package;
      enableZshIntegration = true;
      settings = {
        preview = let scaleDown = builtins.div 1.0 cfg.scale;
        in {
          max_width = 1200;
          max_height = 1800;
          ueberzug_scale = scaleDown;
          # First two elements: x, y
          # Shift the preview away from the left and top border.
          # Last two elements: w, h
          # Reduce the preview size to keep it away from the right and bottom border.
          ueberzug_offset = [ scaleDown scaleDown (-scaleDown) (-scaleDown) ];
        };
      };
    };
    xdg.configFile."yazi/theme.toml".source = let
      templateData = if state.theme == "light" then {
        theme = ./themes/catppuccin-latte.toml.jinja;
        syntectTheme = ./themes/catppuccin-latte.tmTheme;
      } else {
        theme = ./themes/catppuccin-mocha.toml.jinja;
        syntectTheme = ./themes/catppuccin-mocha.tmTheme;
      };
    in templateFile "yazi-theme.toml" templateData templateData.theme;

    xdg.configFile."yazi/keymap.toml".source = ./keymap.toml;
    xdg.configFile."yazi/init.lua".source = ./init.lua;
  };
}
