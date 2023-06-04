{ config, pkgs, state, nixinfo, hostname, ... }:

let parallel = pkgs.parallel-full.override (old: { willCite = true; });
in {
  programs.home-manager.enable = true;

  imports = [
    ../features/app/git
    ../features/app/vim
    ../features/app/tmux
    ../features/app/powerline
    ../features/app/fzf
    ../features/app/tealdeer
    ../features/conf/misc-dotfiles
  ];

  home.packages = (with pkgs; [
    nixfmt
    exa
    fd
    htop
    lsof
    ripgrep
    silver-searcher
    bind
    hunspell
    hunspellDicts.en_US-large
    direnv
    parallel
  ]);

  my.services.nix-home-manager-gc.enable = true;
  my.programs.zsh.enable = true;
  my.programs.fontconfig.enable = true;
  my.programs.emacs.enable = true;
  my.programs.set-theme.enable = true;
  programs.bottom = {
    enable = true;
    settings = {
      flags = {
        color = (if state.theme == "light" then "gruvbox-light" else "gruvbox");
      };
    };
  };
  my.programs.ranger.enable = true;
  my.programs.navi.enable = true;
  my.programs.hmSwitch.enable = true;
}
