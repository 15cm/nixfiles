{ nixpkgs, ... }:

with nixpkgs.lib; {
  # Adds my custom packages
  additions = final: _prev: import ../pkgs { pkgs = final; };
  modifications = final: prev: rec {
    trash-cli = prev.trash-cli.overrideAttrs (old: { postInstall = ""; });
  };
}
