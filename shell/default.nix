{
  pkgs,
  jailed-agents,
  system,
}:

let
  lib = import ./lib.nix { inherit pkgs jailed-agents system; };
  shellConfig = lib.mkJailedShellConfig [ ];
  agents = import ../lib/agents.nix {
    inherit pkgs jailed-agents system;
    baseReadonlyDirs = shellConfig.extraReadonlyDirs;
    basePackages = lib.defaultPkgs;
  };
in

pkgs.mkShell {
  packages = lib.defaultPkgs ++ [
    (jailed-agents.lib.${system}.makeJailedOpencode shellConfig)
    (jailed-agents.lib.${system}.makeJailedClaudeCode shellConfig)
    (jailed-agents.lib.${system}.makeJailedCrush shellConfig)
    (lib.makeJailedCodex {
      extraPkgs = shellConfig.extraPkgs;
      extraReadonlyDirs = shellConfig.extraReadonlyDirs;
    })
  ];
}
