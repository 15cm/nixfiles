{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.programs.nvim;
in {
  options.my.programs.nvim = { enable = mkEnableOption "Neo Vim"; };
  config = mkIf cfg.enable { programs.nixvim = { enable = true; }; };
}
