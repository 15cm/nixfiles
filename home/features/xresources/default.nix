{ withArgs, ... }:

{
  xresources.properties = {
    "Xft.rgba" = "rgb";
    "Xft.antialias" = true;
    "Xft.hinting" = true;
    "Xft.lcdfilter" = "lcddefault";
  } // withArgs.propertiesOverride or { };
}
