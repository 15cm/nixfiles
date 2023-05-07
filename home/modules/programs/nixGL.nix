{ config, pkgs, lib, ... }:

with lib;
let cfg = config.my.programs.nixGL;
in {

  options.my.programs.nixGL = {
    enable = mkEnableOption "nixGL";
    package = mkOption {
      type = types.package;
      default = pkgs.nixgl.auto.nixGLDefault;
    };
  };
  config = mkIf cfg.enable { home.packages = [ cfg.package ]; };
}
