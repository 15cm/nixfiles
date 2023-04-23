{ nixpkgs, ... }:

with nixpkgs.lib; {
  # Adds my custom packages
  additions = self: _super: import ../pkgs { pkgs = self; };

  modifications = self: super: {
    goldendict = super.goldendict.overrideAttrs (old: {
      version = "2023-05-07";
      src = super.fetchFromGitHub {
        owner = "goldendict";
        repo = "goldendict";
        rev = "6f82f388d1a8d9e9d9dd1aef8dd38b370bbdca2e";
        sha256 = "sha256-ORcBYqkloZNWk6RDXVGHfOhFzPI/7RlKNUWBYx+1PUY=";
      };
    });
    waybar = super.waybar.overrideAttrs (old: {
      mesonFlags = old.mesonFlags ++ [ "-Dexperimental=true" ];
    });
    flameshot = super.flameshot.overrideAttrs (old: {
      src = super.fetchFromGitHub {
        owner = "flameshot-org";
        repo = "flameshot";
        rev = "3ededae5745761d23907d65bbaebb283f6f8e3f2";
        hash = "sha256-4SMg63MndCctpfoOX3OQ1vPoLP/90l/KGLifyUzYD5g=";
      };
      buildInputs = old.buildInputs ++ [super.pkgs.libsForQt5.kguiaddons];
      cmakeFlags = [ "-DUSE_WAYLAND_GRIM=true" ];
    });
  };
}
