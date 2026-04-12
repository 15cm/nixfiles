{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.my.programs.obsidian;
in
{
  options.my.programs.obsidian = {
    enable = mkEnableOption "Obsidian";
  };

  config = mkIf cfg.enable {
    programs.obsidian.enable = true;
  };
}
