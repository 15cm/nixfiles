{ pkgs ? null, ... }: {
  clipper = pkgs.callPackage ./clipper { };
  i3-quickterm = pkgs.callPackage ./i3-quickterm {};
}
