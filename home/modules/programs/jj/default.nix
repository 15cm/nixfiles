{ config, lib, ... }:

with lib;
let
  cfg = config.my.programs.jj;
in {
  options.my.programs.jj = {
    enable = mkEnableOption "Jujutsu";
  };

  config = mkIf cfg.enable {
    programs.jujutsu = {
      enable = true;
      settings = {
        ui.default-command = "log";
        user = {
          name = "Sinkerine";
          email = "git@15cm.net";
        };
      };
    };
  };
}
