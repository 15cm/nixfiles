{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.programs.pythonDevTools;
in {
  options.my.programs.pythonDevTools = {
    enable = mkEnableOption "pythonDevTools";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # pdm is blocked for now by https://github.com/NixOS/nixpkgs/pull/513116.
      pyright
      black
      isort
      python313Packages.docformatter
    ];
  };
}
