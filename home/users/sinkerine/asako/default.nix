args@{ pkgs, ... }:

{
  home.stateVersion = "22.05";

  imports = [
    ../common
    ../common/linux-gui.nix
    ../../../features/conf/kmonad
    ../../../features/app/easyeffects
  ];
}
