{ pkgs, ... }:

{
  programs.home-manager.enable = true;

  imports =
    [ ../features/emacs ../features/tmux ../features/zsh ../features/navi ];

  home.packages = [
    pkgs.exa
    pkgs.fd
  ];
}
