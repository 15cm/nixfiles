{ config, lib, ... }:

with lib;
let
  cfg = config.my.programs.codex;
in
{
  options.my.programs.codex = {
    enable = mkEnableOption "Codex";
  };

  config = mkIf cfg.enable {
    programs.codex = {
      enable = true;
    };
  };
}
