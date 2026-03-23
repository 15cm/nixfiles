{
  pkgs,
  jailed-agents,
  system,
  extraPkgs ? [ ],
}:

let
  lib = import ./lib.nix { inherit pkgs jailed-agents system; };
  shellPkgs = lib.defaultPkgs ++ extraPkgs;
in

pkgs.mkShell {
  packages = shellPkgs ++ [
    pkgs.codex-notify
    (lib.makeJailedOpencode [ ])
    (lib.makeJailedClaudeCode [ ])
    (lib.makeJailedCodex {
      extraPkgs = shellPkgs ++ [ pkgs.codex-notify ];
      extraReadonlyDirs = lib.defaultReadonlyDirs;
    })
  ];
}
