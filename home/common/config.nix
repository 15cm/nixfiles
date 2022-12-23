{ pkgs, config, nixinfo, lib, ... }:

with lib;

{
  isNixOs = config.home.username == "sinkerine";
}
