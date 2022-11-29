{ pkgs, config, nixinfo, ... }:

{
  nixinfo = rec {
    projectRoot = "${config.home.homeDirectory}/${nixinfo.projectRoot}";
    flakeUri = "path:${projectRoot}#${nixinfo.configName}";
  };
  shell = { binary = "${pkgs.zsh}/bin/zsh"; };
  clipper = rec {
    address = "localhost";
    port = 8377;
    copyCommand = "nc " + (if pkgs.stdenv.isLinux then " -q0" else "")
      + "localhost ${toString port}";
  };
}
