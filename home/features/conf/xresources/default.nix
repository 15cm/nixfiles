{ hostname, ... }:

{
  xresources.properties = {
    "Xft.rgba" = "rgb";
    "Xft.antialias" = true;
    "Xft.hinting" = true;
    "Xft.lcdfilter" = "lcddefault";
  } // (if hostname == "akako" then {
    "Xft.dpi" = 120;
    "Xcursor.size" = 30;
  } else {
    "Xft.dpi" = 192;
    "Xcursor.size" = 48;
  });
}
