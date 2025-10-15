{ config, pkgs, lib, ... }:

with lib;
let cfg = config.my.programs.baidupcs-go;
in {
  options.my.programs.baidupcs-go = { enable = mkEnableOption "baidupcs-go"; };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.baidupcs-go ];
  };
}
