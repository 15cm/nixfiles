args@{ pkgs, ... }:

{
  home.stateVersion = "22.05";

  imports = [
    ../common/baseline.nix
    ../common/linux-gui.nix
    ../../../features/conf/kmonad
    ../../../features/app/easyeffects
  ];
}
