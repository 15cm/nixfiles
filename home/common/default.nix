{ nixpkgs, pkgs, ... }:

{
  programs.home-manager.enable = true;

  nixpkgs.overlays = [
    (import (builtins.fetchGit {
      url = "https://github.com/nix-community/emacs-overlay.git";
      ref = "master";
      rev = "c231c73992cf9a024070b841fdcfdf067da1a3dd";
    }))
  ];

  imports = [
    ../features/tmux
    ../features/zsh
    ../features/navi
    ../features/powerline
    ../features/misc-dotfiles
  ];

  home.packages = [ pkgs.exa pkgs.fd ];
}
