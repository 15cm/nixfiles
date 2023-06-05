{ pkgs, fetchzip }:

let
  pname = "AriaNg";
  version = "1.3.6";
in pkgs.stdenv.mkDerivation {
  inherit pname version;
  src = fetchzip {
    url =
      "https://github.com/mayswind/AriaNg/releases/download/${version}/AriaNg-${version}-AllInOne.zip";
    stripRoot = false;
    hash = "sha256-xDwo72vW+apIVxGNvcEWo7I9cKsUarXf06YH9KazxHw=";
  };
  phases = [ "installPhase" ];
  installPhase = ''
    outdir=$out/share/AriaNg
    mkdir -p $outdir
    cp -r $src/* $outdir/
  '';
}
