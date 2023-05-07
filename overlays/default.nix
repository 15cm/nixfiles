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
  };
}
