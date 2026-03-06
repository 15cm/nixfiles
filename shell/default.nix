{
  pkgs,
  jailed-agents,
  system,
}:

let
  sharedConfig = {
    extraPkgs = [
      pkgs.git
      pkgs.gh
    ];
    extraReadonlyDirs = [
      "~/.config/git"
      "/nix/store"
    ];
  };
in

pkgs.mkShell {
  packages = [
    (jailed-agents.lib.${system}.makeJailedOpencode sharedConfig)
    (jailed-agents.lib.${system}.makeJailedClaudeCode sharedConfig)
  ];
}
