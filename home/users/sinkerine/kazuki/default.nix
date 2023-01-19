args@{ pkgs, ... }:

{
  home.stateVersion = "22.05";

  imports = [ ../common ../common/linux-gui.nix ../../../features/app/openrgb ];

  xdg.desktopEntries = {
    yuzu = {
      name = "yuzu (high priority)";
      exec = "nice -n -10 yuzu %f";
      terminal = false;
    };
  };
}
