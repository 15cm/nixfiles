{ ... }:

{
  nix = {
    nixpkgs.overlays = [
      (import (builtins.fetchGit {
        url = "https://github.com/nix-community/emacs-overlay.git";
        ref = "master";
        rev = "c231c73992cf9a024070b841fdcfdf067da1a3dd";
      }))
    ];
  };
}
