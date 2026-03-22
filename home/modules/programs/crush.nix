{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.programs.crush;
in
{
  options.my.programs.crush = {
    enable = mkEnableOption "crush";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.crush ];
  };
}
