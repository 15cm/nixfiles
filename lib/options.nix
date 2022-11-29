{ lib, ... }:

{
  mkDefaultTrueEnableOption = name:
    (lib.mkEnableOption name) // {
      default = true;
    };
}
