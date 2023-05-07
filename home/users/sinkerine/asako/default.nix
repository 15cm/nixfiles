args@{ pkgs, ... }:

{
  home.stateVersion = "22.05";

  imports =
    [ ../common ../common/linux-gui.nix ../../../features/app/easyeffects ];

  home.packages = with pkgs; [ radeontop ];
  my.programs.nixGL.package = with pkgs.nixgl; (nixGLCommon nixGLIntel);
}
