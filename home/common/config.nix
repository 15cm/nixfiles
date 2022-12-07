{ pkgs, config, nixinfo, lib, ... }:

with lib;

{
  nixinfo = rec {
    projectRoot = "${config.home.homeDirectory}/${nixinfo.projectRoot}";
    flakeUri = "path:${projectRoot}#${nixinfo.configName}";
  };
  clipper = rec {
    address = "localhost";
    port = 8377;
    copyCommand = concatStringsSep " " ([ "nc" ]
      ++ optionals pkgs.stdenv.isLinux [ "-N" ]
      ++ [ "localhost ${toString port}" ]);
  };
}
