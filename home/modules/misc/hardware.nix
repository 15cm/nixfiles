{ lib, ... }:

with lib; {
  options = {
    my.hardware.monitors = mkOption {
      default = { };
      type = with types;
        attrsOf (submodule {
          options = {
            output = mkOption {
              type = types.str;
              default = null;
              example = literalExpression "DP-1";
            };
            wallpaper = mkOption {
              type = types.str;
              default = null;
              example = literalExpression "wallpaper.png";
            };
          };
        });
    };
    my.hardware.display.scale = mkOption {
      type = types.float;
      default = 1.0;
    };
  };
}
