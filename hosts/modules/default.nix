{ lib, ... }:

with lib; {
  imports = [ ./misc ./services ./programs ];
}
