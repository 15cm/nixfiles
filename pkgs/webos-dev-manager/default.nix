{ appimageTools, fetchurl }:
let
  pname = "webos-dev-manager";
  version = "1.99.16";

  src = fetchurl {
    url =
      "https://github.com/webosbrew/dev-manager-desktop/releases/download/v${version}/${pname}_${version}_amd64.AppImage";
    hash = "sha256-1Eg8flL81vJXcGG9492tePqI4LpvEap2spuYtfIwAKU=";
  };
in appimageTools.wrapType2 { inherit pname version src; }
