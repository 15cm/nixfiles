{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.clipper;
  yamlFormat = pkgs.formats.yaml { };
in {
  options = {
    programs.clipper = {
      enable = mkEnableOption "clipper";
      package = mkOption {
        type = types.package;
        default = pkgs.clipper;
        defaultText = literalExpression "pkgs.clipper";
        description = "The clipper package to install.";
      };

      settings = mkOption {
        type = yamlFormat.type;
        default = { };
        example = literalExpression ''
          {ext.shell.theme = "default"}
        '';
      };

      configPath = mkOption {
        type = types.str;
        default = "${config.xdg.configHome}/clipper/clipper.json";
        description = "Config file path of clipper";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    { home.packages = [ cfg.package ]; }
    (mkIf (cfg.settings != { }) {
      home.file."${cfg.configPath}".text = builtins.toJSON cfg.settings;
    })
  ]);
}
