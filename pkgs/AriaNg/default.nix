{ pkgs, fetchzip }:

let
  pname = "AriaNg";
  version = "1.3.2";
in pkgs.stdenv.mkDerivation {
  inherit pname version;
  src = fetchzip {
    url =
      "https://github.com/mayswind/AriaNg/releases/download/${version}/AriaNg-${version}-AllInOne.zip";
    stripRoot = false;
    hash = "sha256-eBdhFY0PgCBt86gyCHCBL9QJzOdgD9I9oj7CZoF8HIc=";
  };
  phases = [ "installPhase" ];
  installPhase = ''
    outdir=$out/share/AriaNg
    mkdir -p $outdir
    cp -r $src/* $outdir/
  '';
}
