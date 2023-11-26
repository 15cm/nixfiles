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
  };
}
