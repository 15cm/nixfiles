args@{ nixpkgs, pkgs, ... }:

let commonConfig = (import ./config.nix args);
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
    (import ../features/app/clipper
      (args // { templateData = { inherit (commonConfig) clipper; }; }))
    ../features/app/ranger
  ];

  home.packages = [ pkgs.exa pkgs.fd pkgs.bottom pkgs.nix-template ];
}
