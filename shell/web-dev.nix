{
  pkgs,
  jailed-agents,
  system,
}:

let
  lib = import ./lib.nix { inherit pkgs jailed-agents system; };
  webPkgs = with pkgs; [
    nodejs
    nodePackages.npm
    nodePackages.typescript
    chromium
  ];
in

pkgs.mkShell {
  packages = webPkgs;
}
