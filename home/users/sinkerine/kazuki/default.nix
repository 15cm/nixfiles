args@{ config, pkgs, ... }:

{
  imports = [
    ../common/default.nix
    (import ../../../features/xresources
      (args // { withArgs.propertiesOverride = { "Xft.dpi" = 192; }; }))
    ../../../features/alacritty
  ];

  home.stateVersion = "22.05";
  programs.home-manager.enable = true;
}
