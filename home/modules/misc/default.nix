{ lib, ... }:

with lib; {
  imports = [ ./env.nix ./display.nix ];
}
