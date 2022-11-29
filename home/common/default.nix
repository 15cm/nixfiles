args@{ nixpkgs, pkgs, ... }:

let commonConfig = (import ./config.nix args);
in {
  programs.home-manager.enable = true;

  imports = [
    ../features/tmux
    ../features/zsh
    ../features/navi
    ../features/powerline
    ../features/misc-dotfiles
    ../features/set-theme
    (import ../features/clipper
      (args // { templateData = { inherit (commonConfig) clipper; }; }))
  ];

  home.packages = [ pkgs.exa pkgs.fd pkgs.bottom ];
}
