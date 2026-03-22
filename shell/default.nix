{
  pkgs,
  jailed-agents,
  system,
}:

let
  lib = import ./lib.nix { inherit pkgs; };
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
  ];
}
