args@{ nixpkgs, pkgs, ... }:

let
  commonConfig = (import ./config.nix args);
  parallel = pkgs.parallel-full.override (old: { willCite = true; });
in {
  programs.home-manager.enable = true;

  imports = [
    ../features/app/git
    ../features/app/emacs
    ../features/app/vim
    ../features/app/tmux
    ../features/app/zsh
    ../features/app/navi
    ../features/app/powerline
    ../features/app/fzf
    ../features/app/set-theme
    (import ../features/app/clipper
      (args // { templateData = { inherit (commonConfig) clipper; }; }))
    ../features/app/ranger
    ../features/conf/misc-dotfiles
    ../features/conf/fontconfig
  ];

  home.packages = (with pkgs; [
    nixfmt
    exa
    fd
    bottom
    nix-template
    xclip
    htop
    lsof
    ripgrep
    silver-searcher
    ueberzug
    bind
    tealdeer
    cloc
    hunspell
    hunspellDicts.en_US-large
    direnv
    emacsPackages.emacsql-sqlite
    traceroute
  ]) ++
    # Packages with overrides.
    [ parallel ];
}
