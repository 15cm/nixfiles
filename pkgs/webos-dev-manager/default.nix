{ appimageTools, fetchurl }:
let
  pname = "webos-dev-manager";
  version = "1.99.3";

  src = fetchurl {
    url =
      "https://github.com/webosbrew/dev-manager-desktop/releases/download/v${version}/${pname}_${version}_amd64.AppImage";
    hash = "sha256-AZABETtuJ89TAqi93WgR1D+0OBd1fTnIIIx4THffr78=";
  };
in appimageTools.wrapType2 { inherit pname version src; }
