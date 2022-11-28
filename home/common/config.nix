{ pkgs, config, specialArgs, ... }:

{
  nix = {
    projectRoot = "${config.home.homeDirectory}/${specialArgs.projectRootUnderHome}";
  };
  shell = {
    binary = "${pkgs.zsh}/bin/zsh";
  };
  clipper = rec {
    listenPort = "8377";
    copyCommand = "nc " + (if pkgs.stdenv.isLinux then " -q0" else "")
      + "localhost ${listenPort}";
  };
}
