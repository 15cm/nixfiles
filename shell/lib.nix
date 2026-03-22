{ pkgs }:

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
}
