{
  pkgs,
  jailed-agents,
  system,
}:

let
  defaultBaseJailOptions = jailed-agents.lib.${system}.commonJailOptions ++ [
    jailed-agents.lib.${system}.internals.jail.combinators.notifications
  ];
in
rec {
  jailedLib = jailed-agents.lib.${system};
  defaultPkgs = with pkgs; [
    git
    git-lfs
    jujutsu
    gh
    openssh
    nix
    gnused
    gnugrep
    gawk
    coreutils
    libnotify
  ];
  defaultReadonlyDirs = [
    "~/.config/git"
    "~/.config/jj"
    "~/.ssh/agent-shared"
    "~/.ssh/config"
    "~/.ssh/known_hosts"
    "/nix/store"
  ];
  baseJailOptions = defaultBaseJailOptions;
  mkJailedShellConfig = extraPkgs: {
    inherit baseJailOptions;
    extraPkgs = defaultPkgs ++ extraPkgs;
    extraReadonlyDirs = defaultReadonlyDirs;
  };
  makeJailedOpencode = extraPkgs: jailedLib.makeJailedOpencode (mkJailedShellConfig extraPkgs);
  makeJailedClaudeCode = extraPkgs: jailedLib.makeJailedClaudeCode (mkJailedShellConfig extraPkgs);
  makeJailedCrush = extraPkgs: jailedLib.makeJailedCrush (mkJailedShellConfig extraPkgs);
  makeJailedCodex =
    {
      name ? "jailed-codex",
      pkg ? pkgs.codex or (throw "codex not found in pkgs; pass pkg explicitly"),
      extraPkgs ? [ ],
      extraReadwriteDirs ? [ ],
      extraReadonlyDirs ? [ ],
      baseJailOptions ? defaultBaseJailOptions,
    }:
    jailedLib.makeJailedAgent {
      inherit
        name
        pkg
        extraPkgs
        extraReadwriteDirs
        extraReadonlyDirs
        baseJailOptions
        ;
      configPaths = [
        "~/.codex"
      ];
    };
}
