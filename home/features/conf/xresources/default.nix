{ hostname, ... }:

{
  xresources.properties = {
    "Xft.rgba" = "rgb";
    "Xft.antialias" = true;
    "Xft.hinting" = true;
    "Xft.lcdfilter" = "lcddefault";
  } // (if hostname == "asako" then {
    "Xft.dpi" = 120;
  } else {
    "Xft.dpi" = 192;
  });
}
