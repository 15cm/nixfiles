{ lib, ... }:

with lib; {
  mkDefaultTrueEnableOption = name:
    (mkEnableOption name) // {
      default = true;
    };
  attrsOption = mkOption {
    default = { };
    type = types.attrs;
  };
}
