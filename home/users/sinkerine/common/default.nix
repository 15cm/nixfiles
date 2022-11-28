args@{ pkgs, ... }:

let commonConfig = (import ./config.nix);
in rec {
  home.username = commonConfig.home.username;
  home.homeDirectory = commonConfig.home.homeDirectory;

  imports = [ ../../../common ];

  home.packages = [ ];

  home.file.".gitignore".source = ../../../plaintext/gitignore;
  home.file.".ideavimrc".source = ../../../plaintext/ideavimrc;

}
