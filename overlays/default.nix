{ nixpkgs, ... }:

with nixpkgs.lib; {
  # Adds my custom packages
  additions = final: _prev: import ../pkgs { pkgs = final; };
  modifications = final: prev: rec {
    waybar = prev.waybar.overrideAttrs
      (old: rec { mesonFlags = old.mesonFlags ++ [ "-Dexperimental=true" ]; });
    goldendict = prev.goldendict.overrideAttrs (old: {
      version = "2023-03-30";
      src = prev.fetchFromGitHub {
        owner = "vedgy";
        repo = "goldendict";
        rev = "7b4a8328806ff2d71c43b229359b2f10724f7e6d";
        sha256 = "sha256-ZQjGpwsWDbWRQkgCt7rMuazt345P+G7XiEjsShulBBs=";
      };
      buildInputs = let pkgs = final;
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
    trash-cli = prev.trash-cli.overrideAttrs (old: { postInstall = ""; });

    # transgui overlays starts.
    # v3.2.3 fixes branch for the CJK characters issue of transgui
    # https://github.com/transmission-remote-gui/transgui/issues/1378
    fpc = prev.fpc.overrideAttrs (old: rec {
      version = "3.2.3";
      src = prev.fetchFromGitLab {
        owner = "fpc";
        repo = "source";
        group = "freepascal.org";
        rev = "36c7b7b655c257c9b52fc48c37b8a246e29b1778";
        sha256 = "sha256-nLS92xcnLW9MlIOqek3B92CeeSkCdIJRTB0oVzZqylo=";
      };
      patches = [ ./fpc/mark-paths.patch ];
      postPatch = builtins.replaceStrings [ "fpcsrc/" ] [ "" ] old.postPatch;
    });
    lazarus = prev.lazarus.overrideAttrs (old: rec {
      version = "2.2.6-0";
      preBuild = ''
        mkdir -p $out/share "$out/lazarus"
        cp -R ${fpc.src} $out/share/fpcsrc
        substituteInPlace ide/include/unix/lazbaseconf.inc \
          --replace '/usr/fpcsrc' "$out/share/fpcsrc"
      '';
    });
    # transgui overlays ends.
    fcitx5 = prev.fcitx5.overrideAttrs (old: rec {
      pname = "fcitx5";
      version = "5.0.23";
      src = prev.fetchFromGitHub {
        owner = "fcitx";
        repo = pname;
        rev = version;
        hash = "sha256-zS25XeNtBN7QIi+Re/p1uLoH/Q4xKAsFrEmgk2LYRu8=";
      };
      patches = [
        # Fix compatiblity with fmt 10.0. Remove with the next release
        (prev.fetchpatch {
          url =
            "https://github.com/fcitx/fcitx5/commit/7fb3a5500270877d93b61b11b2a17b9b8f6a506b.patch";
          hash = "sha256-Z4Sqdyp/doJPTB+hEUrG9vncUP29L/b0yJ/u5ldpnds=";
        })
      ];
    });
    fcitx5-rime = prev.fcitx5-rime.overrideAttrs (old: rec {
      pname = "fcitx5-rime";
      version = "5.0.16";
      src = prev.fetchFromGitHub {
        owner = "fcitx";
        repo = pname;
        rev = version;
        hash = "sha256-YAunuxdMlv1KOj2/xXstb/Uhm97G9D9rxb35AbNgMaE=";
      };
    });
  };
}
