{ pkgs, config, ... }:

{
  home.packages = [ config.services.unclutter.package ];
  services.unclutter = { enable = true; };
}
