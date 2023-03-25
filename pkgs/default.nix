{ pkgs ? null, ... }:

with pkgs; {
  clipper = callPackage ./clipper { };
  i3-quickterm = callPackage ./i3-quickterm { };
  ranger_devicons = callPackage ./ranger_devicons { };
  AriaNg = callPackage ./AriaNg { };
  myEmacs = (emacsPackagesFor emacsUnstable).emacsWithPackages
      (epkgs: with epkgs; [ emacsql-sqlite ]);
  myEmacs-nox = (emacsPackagesFor emacsUnstable-nox).emacsWithPackages
      (epkgs: with epkgs; [ emacsql-sqlite ]);
  sarasa-gothic-nerdfont = (callPackage ./sarasa-gothic-nerdfont { });
}
