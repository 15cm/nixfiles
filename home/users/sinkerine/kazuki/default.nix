args@{ pkgs, ... }:

{
  home.stateVersion = "22.05";

  imports = [ ../common ../common/linux-gui.nix ../../../features/app/openrgb ];

  xdg.desktopEntries = {
    ryujinx = {
      name = "ryujinx (high priority)";
      exec = "nice -n -19 ryujinx %f";
      terminal = false;
    };
  };
}
