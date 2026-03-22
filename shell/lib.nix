{
  pkgs,
  jailed-agents,
  system,
}:

rec {
  defaultPkgs = with pkgs; [
    git
    gh
    openssh
    nix
    gnused
    gnugrep
    gawk
    coreutils
  ];
  mkJailedShellConfig = extraPkgs: {
    extraPkgs = defaultPkgs ++ extraPkgs;
    extraReadonlyDirs = [
      "~/.config/git"
      "~/.ssh/agent-shared"
      "~/.ssh/config"
      "~/.ssh/known_hosts"
      "/nix/store"
    ];
  };
  makeJailedCodex =
    {
      name ? "jailed-codex",
      pkg ? pkgs.codex or (throw "codex not found in pkgs; pass pkg explicitly"),
      extraPkgs ? [ ],
      extraReadwriteDirs ? [ ],
      extraReadonlyDirs ? [ ],
    }:
    jailed-agents.lib.${system}.makeJailedAgent {
      inherit
        name
        pkg
        extraPkgs
        extraReadwriteDirs
        extraReadonlyDirs
        ;
      configPaths = [
        "~/.codex"
      ];
    };
}
