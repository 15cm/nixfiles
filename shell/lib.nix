{
  pkgs,
  jailed-agents,
  system,
}:

let
  ghTokenRuntimePath = "$HOME/.config/sops-nix/secrets/githubToken";
  defaultBaseJailOptions = jailed-agents.lib.${system}.commonJailOptions ++ [
    jailed-agents.lib.${system}.internals.jail.combinators.notifications
    (jailed-agents.lib.${system}.internals.jail.combinators.wrap-entry (entry: ''
      if [ -r "${ghTokenRuntimePath}" ]; then
        GH_TOKEN="$(< "${ghTokenRuntimePath}")"
        export GH_TOKEN
        export GITHUB_TOKEN="$GH_TOKEN"
      fi

      exec ${entry}
    ''))
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
  defaultReadwriteDirs = [
    # To try all local developed projects.
    "/nixfiles"
  ];
  defaultReadonlyDirs = [
    # Mounted so jailed agents can initialize GH_TOKEN inside the jail.
    "~/.config/sops-nix/secrets/githubToken"
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
    extraReadwriteDirs = defaultReadwriteDirs;
    extraReadonlyDirs = defaultReadonlyDirs;
  };
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
