args@{ nixpkgs, pkgs, ... }:

let
  commonConfig = (import ./config.nix args);
  parallel = pkgs.parallel-full.override (old: { willCite = true; });
in {
  programs.home-manager.enable = true;

  imports = [
    ../features/app/git
    ../features/app/vim
    ../features/app/tmux
    ../features/app/zsh
    ../features/app/navi
    ../features/app/powerline
    ../features/app/fzf
    ../features/app/set-theme
    ../features/app/ranger
    ../features/app/tealdeer
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
    cloc
    hunspell
    hunspellDicts.en_US-large
    direnv
    traceroute
  ]) ++
    # Packages with overrides.
    [ parallel ];

  my.programs.emacs.enable = true;
}
