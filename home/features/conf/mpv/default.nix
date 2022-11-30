{ mylib, hostname, pkgs, ... }:

let
  inherit (mylib) templateFile;
  templateData = { inherit hostname; };
in {
  xdg.configFile."mpv/mpv.conf".source =
    templateFile "mpv-conf" templateData ./mpv.conf.jinja;
}
