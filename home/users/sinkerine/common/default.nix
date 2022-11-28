args@{ pkgs, ... }:

let commonConfig = (import ./config.nix args);
in rec {
  home.username = commonConfig.home.username;
  home.homeDirectory = commonConfig.home.homeDirectory;

  imports = [ ../../../common ];
}
