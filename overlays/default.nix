{ nixpkgs, ... }:

with nixpkgs.lib; {
  # Adds my custom packages
  additions = self: _super: import ../pkgs { pkgs = self; };
  modifications = self: super: {
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
    # flameshot = super.flameshot.overrideAttrs (old: {
    #   src = super.fetchFromGitHub {
    #     owner = "flameshot-org";
    #     repo = "flameshot";
    #     rev = "3ededae5745761d23907d65bbaebb283f6f8e3f2";
    #     hash = "sha256-4SMg63MndCctpfoOX3OQ1vPoLP/90l/KGLifyUzYD5g=";
    #   };
    #   buildInputs = old.buildInputs ++ [ super.pkgs.libsForQt5.kguiaddons ];
    #   cmakeFlags = [ "-DUSE_WAYLAND_GRIM=true" ];
    # });
  };
}
