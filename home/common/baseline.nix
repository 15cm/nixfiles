{ pkgs, state, ... }:

let parallel = pkgs.parallel-full.override (old: { willCite = true; });
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
    ../features/app/tealdeer
    ../features/conf/misc-dotfiles
  ];

  home.packages = (with pkgs; [
    nixfmt
    exa
    fd
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
  programs.bottom = {
    enable = true;
    settings = {
      flags = {
        color = (if state.theme == "light" then "gruvbox-light" else "gruvbox");
      };
    };
  };
  my.programs.ranger.enable = true;
}
