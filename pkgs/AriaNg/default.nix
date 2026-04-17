{
  lib,
  fetchzip,
  stdenvNoCC,
}:

let
  pname = "AriaNg";
  version = "1.3.13";
in stdenvNoCC.mkDerivation {
  inherit pname version;
  src = fetchzip {
    url =
      "https://github.com/mayswind/AriaNg/releases/download/${version}/AriaNg-${version}-AllInOne.zip";
    stripRoot = false;
    hash = "sha256-wOlcogJOBCFEj+b89DWfnpwaSfA/N8pM/WaGQqhrrMQ=";
  };
  phases = [ "installPhase" ];
  installPhase = ''
    outdir=$out/share/AriaNg
    mkdir -p $outdir
    cp -r $src/* $outdir/
  '';

  meta = with lib; {
    description = "Modern web frontend for aria2";
    homepage = "https://github.com/mayswind/AriaNg";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
