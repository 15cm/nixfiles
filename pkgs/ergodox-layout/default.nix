{ stdenvNoCC, ... }:

stdenvNoCC.mkDerivation {
  name = "ergodox-layout";
  src = ./src;

  installPhase = ''
    mkdir -p $out
    cp -r . $out/
  '';

  meta.description = "QMK keymap source for ErgoDox EZ (home layout)";
}
