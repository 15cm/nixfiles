{ pkgs, config, ... }:

{
  home.packages = [ config.services.syncthing.tray.package ];
  services.syncthing = {
    enable = true;
    tray = { enable = true; };
  };
}
