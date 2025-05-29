{ appimageTools, fetchurl }:
let
  pname = "webos-dev-manager";
  version = "1.99.13";

  src = fetchurl {
    url =
      "https://github.com/webosbrew/dev-manager-desktop/releases/download/v${version}/${pname}_${version}_amd64.AppImage";
    hash = "sha256-9jzdepZCiORX0nQCQenpFdOFsQaLWxa7/m4j0iCGlLI";
  };
in appimageTools.wrapType2 { inherit pname version src; }
