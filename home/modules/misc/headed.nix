{ lib, ... }:

with lib;
{
  options.my.isHeaded = mkOption {
    type = types.bool;
    default = true;
  };
}
