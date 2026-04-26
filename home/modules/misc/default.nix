{ lib, ... }:

with lib;
{
  imports = [
    ./env.nix
    ./display.nix
    ./ids.nix
    ./gui.nix
    ./ai-agents.nix
    ./trusted.nix
  ];
}
