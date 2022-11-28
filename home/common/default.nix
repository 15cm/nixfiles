{ pkgs, ... }:

{
  programs.home-manager.enable = true;

  imports = [ ../features/emacs ../features/tmux ../features/zsh];

  home.packages = [ pkgs.exa ];
}
