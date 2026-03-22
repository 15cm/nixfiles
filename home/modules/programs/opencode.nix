{ config, lib, ... }:

with lib;
let
  cfg = config.my.programs.opencode;
in
{
  options.my.programs.opencode = {
    enable = mkEnableOption "OpenCode";
    theme = mkOption {
      type = types.str;
      default = "opencode";
      description = "OpenCode theme";
    };
    model = mkOption {
      type = types.str;
      default = "anthropic/claude-haiku-4-5-20251001";
      description = "Default model to use";
    };
    autoshare = mkOption {
      type = types.bool;
      default = false;
      description = "Enable automatic sharing";
    };
    autoupdate = mkOption {
      type = types.bool;
      default = true;
      description = "Enable automatic updates";
    };
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      settings = {
        theme = cfg.theme;
        model = cfg.model;
        autoshare = cfg.autoshare;
        autoupdate = cfg.autoupdate;
      };
    };
  };
}
