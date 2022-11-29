{ config, lib, pkgs, ... }:

with lib;

let cfg = config.programs.i3;
in {
  options = {
    programs.i3 = {
      enable = mkEnableOption "i3";
      package = mkOption {
        type = types.package;
        default = pkgs.i3;
        defaultText = literalExpression "pkgs.i3";
        description = "The i3 package to install.";
      };

      extraConfigTop = mkOption {
        type = types.str;
        default = "";
      };

      extraConfigBottom = mkOption {
        type = types.str;
        default = "";
      };

      barConfigInsideBracket = mkOption {
        type = with types; nullOr str;
        default = "";
      };

      configPath = mkOption {
        type = types.str;
        default = "${config.xdg.configHome}/i3/config";
        description = "Config file path of i3";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    home.file."${cfg.configPath}".text = extraConfigTop
      + (optionalString (barConfigInsideBracket != null) ''

        bar {
          ${barConfigInsideBracket}
        }

      '') + extraConfigBottom;
  };
}
