{ hostname, ... }:

{
  xresources.properties = {
    "Xft.rgba" = "rgb";
    "Xft.antialias" = true;
    "Xft.hinting" = true;
    "Xft.lcdfilter" = "lcddefault";
  } // (if hostname == "asako" then {
    "Xft.dpi" = 120;
    "Xcursor.size" = 32;
  } else {
    "Xft.dpi" = 192;
    "Xcursor.size" = 48;
  });
}
