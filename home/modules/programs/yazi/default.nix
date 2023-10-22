{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.programs.yazi;
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
        preview.ueberzug = let offset = builtins.div 1.0 cfg.scale;
        in {
          scale_down_factor = cfg.scale;
          x_offset = offset;
          y_offset = offset;
          width_offset = -offset;
          height_offset = -offset;
        };
      };
    };
  };
}
