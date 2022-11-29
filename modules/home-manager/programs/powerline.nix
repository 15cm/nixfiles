{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.powerline;
  yamlFormat = pkgs.formats.yaml { };
in {
  options = {
    programs.powerline = {
      enable = mkEnableOption "powerline";
      package = mkOption {
        type = types.package;
        default = pkgs.python3Packages.powerline;
        defaultText = literalExpression "pkgs.python3Packages.powerline";
        description = "The powerline package to install.";
      };

      enableZshIntegration = mkEnableOption "zsh integration";
      enableTmuxIntegration = mkEnableOption "tmux integration";

      configDir = mkOption {
        type = types.str;
        default = "${config.xdg.configHome}/powerline";
        description = "Config directory of powerline";
      };

      settings = mkOption {
        type = yamlFormat.type;
        default = { };
        example = literalExpression ''
          {ext.shell.theme = "default"}
        '';
      };

      colors = mkOption {
        type = yamlFormat.type;
        default = { };
        example = literalExpression ''
          {
            colors = {
              black = 16;
              white = 231;
            };
          }
        '';
      };

      colorSchemes = mkOption {
        type = types.attrsOf yamlFormat.type;
        default = { };
        example = literalExpression ''
          {
            nord = {name = "default};
            "solarized-light" = {name = "default"}
          }
        '';
      };

      colorSchemesShell = mkOption {
        type = types.attrsOf yamlFormat.type;
        default = { };
        example = literalExpression ''
          {
            nord = {name = "default};
            "solarized-light" = {name = "default"}
          }
        '';
      };

      colorSchemesTmux = mkOption {
        type = types.attrsOf yamlFormat.type;
        default = { };
        example = literalExpression ''
          {
            nord = {name = "default};
            "solarized-light" = {name = "default"}
          }
        '';
      };

      themesShell = mkOption {
        type = types.attrsOf yamlFormat.type;
        default = { };
        example = literalExpression ''
          {
            default = {segments.above = [];};
          }
        '';
      };

      themesTmux = mkOption {
        type = types.attrsOf yamlFormat.type;
        default = { };
        example = literalExpression ''
          {
            default = {segments.above = [];};
          }
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    { home.packages = [ cfg.package ]; }
    ({
      programs.zsh.initExtra = mkIf (cfg.enableZshIntegration) ''
        # Powerline
        source ${cfg.package}/share/zsh/powerline.zsh
      '';
    })
    ({
      programs.tmux.extraConfig = mkIf (cfg.enableTmuxIntegration) ''
        # Powerline
        source ${pkgs.python3Packages.powerline}/share/tmux/powerline.conf
      '';
    })
    (mkIf (cfg.settings != { }) {
      home.file."${cfg.configDir}/config.json".text =
        builtins.toJSON cfg.settings;
    })
    (mkIf (cfg.colors != { }) {
      home.file."${cfg.configDir}/colors.json".text =
        builtins.toJSON cfg.colors;
    })
    (mkIf (cfg.colorSchemes != { }) {
      home.file = (mapAttrs' (k: v:
        nameValuePair "${cfg.configDir}/colorschemes/${k}.json" {
          text = builtins.toJSON v;
        }) cfg.colorSchemes);
    })
    (mkIf (cfg.colorSchemesShell != { }) {
      home.file = (mapAttrs' (k: v:
        nameValuePair "${cfg.configDir}/colorschemes/shell/${k}.json" {
          text = builtins.toJSON v;
        }) cfg.colorSchemesShell);
    })
    (mkIf (cfg.colorSchemesTmux != { }) {
      home.file = (mapAttrs' (k: v:
        nameValuePair "${cfg.configDir}/colorschemes/tmux/${k}.json" {
          text = builtins.toJSON v;
        }) cfg.colorSchemesTmux);
    })
    (mkIf (cfg.themesShell != { }) {
      home.file = (mapAttrs' (k: v:
        nameValuePair "${cfg.configDir}/themes/shell/${k}.json" {
          text = builtins.toJSON v;
        }) cfg.themesShell);
    })
    (mkIf (cfg.themesTmux != { }) {
      home.file = (mapAttrs' (k: v:
        nameValuePair "${cfg.configDir}/themes/tmux/${k}.json" {
          text = builtins.toJSON v;
        }) cfg.themesTmux);
    })
  ]);
}
