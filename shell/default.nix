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
    pkgs.claude-notify
    pkgs.codex-notify
    (lib.makeJailedClaudeCode (shellPkgs ++ [ pkgs.claude-notify ]))
    (lib.makeJailedCodex {
      extraPkgs = shellPkgs ++ [ pkgs.codex-notify ];
      extraReadwriteDirs = lib.defaultReadwriteDirs;
      extraReadonlyDirs = lib.defaultReadonlyDirs;
    })
  ];
}
