{ nixpkgs, ... }:

with nixpkgs.lib; {
  # Adds my custom packages
  additions = self: _super: import ../pkgs { pkgs = self; };

  modifications = self: super: {
    calibre = super.calibre.overrideAttrs (old: {
      patches = old.patches ++ [
        (super.fetchpatch {
          name =
            "0026-TypeError-HistoryLineEdit.__init__-got-an-unexpected.patch";
          url =
            "https://raw.githubusercontent.com/debian-calibre/calibre/master/debian/patches/0026-TypeError-HistoryLineEdit.__init__-got-an-unexpected.patch";
          hash = "sha256-W9W6O2pbOOBk93BhYsVYhaqLs6ymDN82cjFKpltlyIc=";
        })
      ];
    });
  };
}
