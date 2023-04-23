args@{ pkgs, ... }:

{
  home.stateVersion = "22.05";

  imports = [ ../common ../common/linux-gui.nix ../../../features/app/openrgb ];

  # Name the entry same as the entry that comes with the package to overwrite it.
  xdg.desktopEntries = {
    ryujinx = {
      name = "ryujinx (high priority)";
      exec = "nice -n -19 ryujinx %f";
      terminal = false;
    };
    vmware-workstation = {
      name = "VMware Workstation (high priority)";
      exec = "env GDK_DPI_SCALE=0.5 nice -n -19 vmware";
    };
  };
}
