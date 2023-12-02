{ nixpkgs, ... }:

with nixpkgs.lib; {
  # Adds my custom packages
  additions = final: _prev: import ../pkgs { pkgs = final; };
  modifications = final: prev: rec {
    waybar = prev.waybar.overrideAttrs
      (old: rec { mesonFlags = old.mesonFlags ++ [ "-Dexperimental=true" ]; });
    goldendict = prev.goldendict.overrideAttrs (old: {
      version = "2023-09-24";
      src = prev.fetchFromGitHub {
        owner = "vedgy";
        repo = "goldendict";
        rev = "2fbca0adfb27427e24c6814c7af650e37bdb7ccb";
        sha256 = "sha256-51wwqo0KfM+GE+LZnpVjdheoqOZWwP5U6TZ7SY8az+Q=";
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
