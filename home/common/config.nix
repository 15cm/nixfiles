{ pkgs, config, nixinfo, lib, ... }:

with lib;

{
  nixinfo = rec {
    projectRoot = "${config.home.homeDirectory}/${nixinfo.projectRoot}";
    flakeUri = "path:${projectRoot}#${nixinfo.configName}";
  };
  shell = { binary = "${pkgs.zsh}/bin/zsh"; };
  clipper = rec {
    address = "localhost";
    port = 8377;
    copyCommand = concatStringsSep " " ([ "nc" ]
      ++ optionals pkgs.stdenv.isLinux [ "-q0" ]
      ++ [ "localhost ${toString port}" ]);
  };
}
