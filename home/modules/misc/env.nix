{ lib, ... }:

with lib; {
  options = {
    my.env = mkOption {
      default = { };
      type = types.attrs;
    };
  };
}
