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

  home.sessionVariables = {
    PATH = "${config.home.homeDirectory}/.nix-profile/bin:$PATH";
  };

  home.file.".imwheelrc".source = ./imwheelrc;
}
