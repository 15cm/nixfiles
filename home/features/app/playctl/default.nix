{ pkgs, config, ... }:

{
  home.packages = [ config.services.playerctld.package ];
  services.playerctld.enable = true;
}
