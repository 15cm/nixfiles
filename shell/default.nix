{
  pkgs,
  jailed-agents,
  system,
}:

let
  lib = import ./lib.nix { inherit pkgs; };
  sharedConfig = lib.mkJailedShellConfig [ ];
in

pkgs.mkShell {
  packages = [
    pkgs.nix
    (jailed-agents.lib.${system}.makeJailedOpencode sharedConfig)
    (jailed-agents.lib.${system}.makeJailedClaudeCode sharedConfig)
  ];
}
