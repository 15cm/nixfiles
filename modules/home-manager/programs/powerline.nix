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
        default = pkgs.powerline;
        defaultText = literalExpression "pkgs.powerline";
        description = "The powerline package to install.";
      };
    };
  };

  config = mkIf cfg.enable { home.packages = [ cfg.package ]; };
}
