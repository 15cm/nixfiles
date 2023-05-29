{ lib, fetchurl, appimageTools }:

let
  pname = "feishin";
  version = "0.1.1";
  src = fetchurl {
    url =
      "https://github.com/jeffvli/feishin/releases/download/v${version}/Feishin-${version}-linux-x86_64.AppImage";
    sha256 = "sha256-H64nks5jZ9QI9FJfni9rbZVCf6A/BE/ruLH0yXoRTks=";
  };
  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in appimageTools.wrapType2 rec {
  inherit pname version src;

  extraInstallCommands = ''
    mv $out/bin/${pname}-${version} $out/bin/${pname}

    install -m 444 -D ${appimageContents}/${pname}.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace 'Exec=AppRun --no-sandbox %U' 'Exec=${pname}'
    cp -r ${appimageContents}/usr/share/icons $out/share
  '';

  meta = with lib; {
    description =
      "Feishin supports any music server that implements a Navidrome or Jellyfin API";
    homepage = "https://github.com/jeffvli/feishin";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ onny ];
    platforms = [ "x86_64-linux" ];
  };
}
