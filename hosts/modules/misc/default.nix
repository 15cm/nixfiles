{ lib, ... }:

with lib; {
  imports = [ ./ids.nix ./trusts.nix ./ports.nix ];
}
