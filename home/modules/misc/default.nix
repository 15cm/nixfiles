{ lib, ... }:

with lib; {
  imports = [ ./env.nix ./hardware.nix ];
}
