{ pkgs ? null, ... }:

with pkgs; {
  clipper = callPackage ./clipper { };
  i3-quickterm = callPackage ./i3-quickterm { };
  ranger_devicons = callPackage ./ranger_devicons { };
  AriaNg = callPackage ./AriaNg { };
  sarasa-gothic-nerdfont = (callPackage ./sarasa-gothic-nerdfont { });
  iosevka-nerdfont = (callPackage ./iosevka-nerdfont { });
  khinsider = (callPackage ./khinsider { });
  feishin = (callPackage ./feishin { });
}
