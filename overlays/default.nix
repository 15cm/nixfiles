{ nixpkgs, ... }:

with nixpkgs.lib; {
  # Adds my custom packages
  additions = self: _super: import ../pkgs { pkgs = self; };
  modifications = self: super: rec {
    goldendict = super.goldendict.overrideAttrs (old: {
      version = "2023-03-30";
      src = super.fetchFromGitHub {
        owner = "vedgy";
        repo = "goldendict";
        rev = "d4d9a0b3dca90be426e5a6dbbf466a0c08d5bdea";
        sha256 = "sha256-D+eZT7cjH4gEB3aczX5JBj9GxU7vbUYrIJo8tZ+JEgw=";
      };
      buildInputs = let pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in with pkgs; [
        qt5.qtbase
        qt5.qtsvg
        qt5.qtwebengine
        qt5.qttools
        qt5.qtx11extras
        libvorbis
        hunspell
        xz
        lzo
        xorg.libXtst
        opencc
        libeb
        libtiff
        libao
        ffmpeg
        zstd
      ];
      qmakeFlags = old.qmakeFlags ++ [ "CONFIG+=use_qtwebengine" ];
    });
    waybar = super.waybar.overrideAttrs
      (old: { mesonFlags = old.mesonFlags ++ [ "-Dexperimental=true" ]; });
    trash-cli = super.trash-cli.overrideAttrs (old: { postInstall = ""; });
    # v3.2.3 fixes branch for the CJK characters issue of transgui
    # https://github.com/transmission-remote-gui/transgui/issues/1378
    fpc = super.fpc.overrideAttrs (old: rec {
      version = "3.2.3";
      src = super.fetchFromGitLab {
        owner = "fpc";
        repo = "source";
        group = "freepascal.org";
        rev = "36c7b7b655c257c9b52fc48c37b8a246e29b1778";
        sha256 = "sha256-nLS92xcnLW9MlIOqek3B92CeeSkCdIJRTB0oVzZqylo=";
      };
      patches = [ ./fpc/mark-paths.patch ];
      postPatch = builtins.replaceStrings [ "fpcsrc/" ] [ "" ] old.postPatch;
    });
    lazarus = super.lazarus.overrideAttrs (old: rec {
      version = "2.2.6-0";
      preBuild = ''
        mkdir -p $out/share "$out/lazarus"
        cp -R ${fpc.src} $out/share/fpcsrc
        substituteInPlace ide/include/unix/lazbaseconf.inc \
          --replace '/usr/fpcsrc' "$out/share/fpcsrc"
      '';
    });
  };
}
