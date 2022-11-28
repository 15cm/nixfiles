{ specialArgs, withArgs, ... }:

{
  xresources.properties = {
    "Xft.rgba" = "rgb";
    "Xft.antialias" = true;
    "Xft.hinting" = true;
    "Xft.lcdfilter" = "lcddefault";
    "test" = builtins.toJSON specialArgs.inputs;
  } // withArgs.propertiesOverride or { };
}
