args@{ pkgs, ... }:

let commonConfig = (import ./config.nix);
in {
  home.username = commonConfig.home.username;
  home.homeDirectory = commonConfig.home.homeDirectory;

  programs.home-manager.enable = true;

  imports = [
    (import ../../../common
      (args // { withArgs.homeDirectory = commonConfig.home.homeDirectory; }))
  ];

  home.packages = [ pkgs.exa ];

  home.file.".gitignore".source = ../../../plaintext/gitignore;
  home.file.".ideavimrc".source = ../../../plaintext/ideavimrc;

}
