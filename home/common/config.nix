{ pkgs, config, specialArgs, ... }:

{
  nix = rec {
    projectRoot =
      "${config.home.homeDirectory}/${specialArgs.projectRootUnderHome}";
    flakeUri = "path:${projectRoot}#${specialArgs.configName}";
  };
  shell = { binary = "${pkgs.zsh}/bin/zsh"; };
  clipper = rec {
    address = "localhost";
    port = 8377;
    copyCommand = "nc " + (if pkgs.stdenv.isLinux then " -q0" else "")
      + "localhost ${toString port}";
  };
}
