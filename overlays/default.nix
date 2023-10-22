{ nixpkgs, ... }:

with nixpkgs.lib; {
  # Adds my custom packages
  additions = self: _super: import ../pkgs { pkgs = self; };
  modifications = self: super: rec {
    waybar = super.waybar.overrideAttrs
      (old: rec { mesonFlags = old.mesonFlags ++ [ "-Dexperimental=true" ]; });
    goldendict = super.goldendict.overrideAttrs (old: {
      version = "2023-03-30";
      src = super.fetchFromGitHub {
        owner = "vedgy";
        repo = "goldendict";
        rev = "7b4a8328806ff2d71c43b229359b2f10724f7e6d";
        sha256 = "sha256-ZQjGpwsWDbWRQkgCt7rMuazt345P+G7XiEjsShulBBs=";
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
    trash-cli = super.trash-cli.overrideAttrs (old: { postInstall = ""; });

    # transgui overlays starts.
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
    # transgui overlays ends.

    yazi = super.yazi.overrideAttrs (old: rec {
      version = "0.1.5";
      src = super.fetchFromGitHub {
        owner = "15cm";
        repo = "yazi";
        rev = "main";
        sha256 = "sha256-AjH+Y/6xpP9lhTiwIOfluMJX2ZTHK5/aZIW0V8tn6cg=";
      };
      cargoDeps = super.pkgs.rustPlatform.fetchCargoTarball {
        inherit src;
        hash = "sha256-tuaxom7GgA3kfJBKuwaPfvletbVAKqDCcSENNMt6pok=";
      };
    });
  };
}
