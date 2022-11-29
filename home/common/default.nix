{ nixpkgs, pkgs, ... }:

{
  programs.home-manager.enable = true;

  imports = [
    ../features/tmux
    ../features/zsh
    ../features/navi
    ../features/powerline
    ../features/misc-dotfiles
    ../features/set-theme
  ];

  home.packages = [ pkgs.exa pkgs.fd ];
}
