{ config, pkgs, ... }:

{
  home.stateVersion = "23.05";

  imports = [
    ../common
    ../common/trusted.nix
  ];

  my.essentials.gui.enable = true;

  my.programs.baidupcs-go.enable = true;
  my.programs.obsidian.enable = true;
}
