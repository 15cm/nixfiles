{ config, mylib, hostname, lib, ... }:

with lib;
let
  inherit (mylib) templateFile;
  templateData = { inherit hostname; };
in {
  xsession = {
    enable = true;
    profileExtra = pipe ./xprofile.sh.jinja [
      (templateFile "xprofile" templateData)
      builtins.readFile
    ];
  };

  home.file.".imwheelrc".source = ./imwheelrc;
}
