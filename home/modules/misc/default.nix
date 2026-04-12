{ lib, ... }:

with lib;
{
  imports = [
    ./env.nix
    ./display.nix
    ./headed.nix
    ./ids.nix
  ];
}
