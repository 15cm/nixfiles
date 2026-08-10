{
  appimageTools,
  fetchurl,
  lib,
}:

let
  pname = "orca-ide";
  version = "1.4.177";

  src = fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux.AppImage";
    hash = "sha256-fOkBbvmRBa0TT00XSX8oQHFuh7ii52owTge5E0w3KLw=";
  };

  contents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -m 444 -D ${contents}/orca-ide.desktop \
      $out/share/applications/orca-ide.desktop
    install -m 444 -D ${contents}/orca-ide.png \
      $out/share/icons/hicolor/512x512/apps/orca-ide.png
    substituteInPlace $out/share/applications/orca-ide.desktop \
      --replace-fail "Exec=AppRun --no-sandbox %U" "Exec=orca-ide %U"
  '';

  meta = {
    description = "Worktree IDE for AI coding agents";
    homepage = "https://www.onorca.dev";
    license = lib.licenses.unfree;
    mainProgram = "orca-ide";
    platforms = [ "x86_64-linux" ];
  };
}
