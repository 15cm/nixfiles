{ lib, ... }:

with lib; {
  mkDefaultTrueEnableOption = name:
    (mkEnableOption name) // {
      default = true;
    };
}
