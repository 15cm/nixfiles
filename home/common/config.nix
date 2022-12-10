{ pkgs, config, nixinfo, lib, ... }:

with lib;

{
  isNixOs = config.home.username == "sinkerine";
  clipper = rec {
    address = "localhost";
    port = 8377;
    copyCommand = concatStringsSep " " ([ "nc" ]
      ++ optionals pkgs.stdenv.isLinux [ "-N" ]
      ++ [ "localhost ${toString port}" ]);
  };
}
