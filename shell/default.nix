{
  pkgs,
  jailed-agents,
  system,
}:

let
  lib = import ./lib.nix { inherit pkgs jailed-agents system; };
in

pkgs.mkShell {
  packages = lib.defaultPkgs ++ [
    (lib.makeJailedOpencode [ ])
    (lib.makeJailedClaudeCode [ ])
    (lib.makeJailedCrush [ ])
    (lib.makeJailedCodex {
      extraPkgs = lib.defaultPkgs;
      extraReadonlyDirs = lib.defaultReadonlyDirs;
    })
  ];
}
