{
  pkgs,
  jailed-agents,
  system,
}:

let
  lib = import ./lib.nix { inherit pkgs; };
  sharedConfig = lib.mkJailedShellConfig (with pkgs; [
    nodejs
    nodePackages.npm
    nodePackages.typescript
    chromium
  ]);
in

pkgs.mkShell {
  packages = [
    (jailed-agents.lib.${system}.makeJailedOpencode sharedConfig)
  ];
}
