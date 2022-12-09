{ lib, mylib, state, ... }:

with lib;
let
  inherit (mylib) templateFile;
  templateData = { inherit (state) theme; };
in {
  programs.vim = {
    enable = true;
    extraConfig = pipe ./vimrc.jinja [
      (templateFile "vimrc" templateData)
      builtins.readFile
    ];
  };
}
