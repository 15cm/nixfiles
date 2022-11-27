args@{ pkgs, ... }:

let constants = (import ./constants.nix);
in {
  imports = [
    (import ../../../features/emacs
      (args // { withArgs.homeDirectory = constants.home.homeDirectory; }))
  ];
  home.username = constants.home.username;
  home.homeDirectory = constants.home.homeDirectory;

  programs.home-manager.enable = true;

  home.packages = [pkgs.exa];

  home.file.".gitignore".source = ../../../plaintext/gitignore;
  home.file.".ideavimrc".source = ../../../plaintext/ideavimrc;
}
