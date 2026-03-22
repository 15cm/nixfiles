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
    home.file.".codex/AGENTS.md".source = ./codex/AGENTS.md;
  };
}
