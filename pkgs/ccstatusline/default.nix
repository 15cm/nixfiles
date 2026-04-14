{
  lib,
  stdenv,
  fetchurl,
  nodejs,
  makeWrapper,
}:

let
  src = fetchurl {
    url = "https://registry.npmjs.org/ccstatusline/-/ccstatusline-2.2.8.tgz";
    hash = "sha256-4+fZ8yDlKwi+mJIMHEkPgyt8vA0kN3FcaEmUbXU7ctw=";
  };
in
stdenv.mkDerivation {
  pname = "ccstatusline";
  version = "2.2.8";

  inherit src;

  nativeBuildInputs = [ makeWrapper ];

  unpackPhase = ''
    tar -xzf $src
    cd package
  '';

  installPhase = ''
    mkdir -p $out/lib/ccstatusline $out/bin
    cp dist/ccstatusline.js $out/lib/ccstatusline/ccstatusline.js
    makeWrapper ${lib.getExe nodejs} $out/bin/ccstatusline \
      --add-flags "$out/lib/ccstatusline/ccstatusline.js"
  '';

  meta = {
    description = "A customizable status line formatter for Claude Code CLI";
    homepage = "https://github.com/sirmalloc/ccstatusline";
    license = lib.licenses.mit;
    mainProgram = "ccstatusline";
  };
}
