{ pkgs ? null, ... }: {
  clipper = pkgs.callPackage ./clipper { };
  i3-quickterm = pkgs.callPackage ./i3-quickterm { };
  ranger_devicons = pkgs.callPackage ./ranger_devicons { };
}
