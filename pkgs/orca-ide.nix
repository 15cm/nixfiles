{
  appimageTools,
  alsa-lib,
  at-spi2-atk,
  autoPatchelfHook,
  cairo,
  cups,
  dbus,
  expat,
  fetchurl,
  glib,
  gtk3,
  lib,
  libdrm,
  libgbm,
  libxkbcommon,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxscrnsaver,
  libxtst,
  libnotify,
  makeWrapper,
  mesa,
  nspr,
  nss,
  pango,
  stdenvNoCC,
  systemd,
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
stdenvNoCC.mkDerivation {
  inherit pname version;

  dontUnpack = true;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libdrm
    libgbm
    libxkbcommon
    mesa
    nspr
    nss
    pango
    systemd
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxscrnsaver
    libxtst
    libnotify
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,opt/orca-ide,share/applications,share/icons/hicolor/512x512/apps}
    cp -r ${contents}/. $out/opt/orca-ide/
    chmod -R u+w $out/opt/orca-ide
    # Old AppImage compatibility libraries pull GTK 2/GConf into an otherwise
    # GTK 3 application. Native Nix libraries provide the needed interfaces.
    rm -rf $out/opt/orca-ide/usr/lib

    install -m 444 ${contents}/orca-ide.desktop \
      $out/share/applications/orca-ide.desktop
    install -m 444 ${contents}/orca-ide.png \
      $out/share/icons/hicolor/512x512/apps/orca-ide.png
    substituteInPlace $out/share/applications/orca-ide.desktop \
      --replace-fail "Exec=AppRun --no-sandbox %U" "Exec=orca-ide %U"

    makeWrapper $out/opt/orca-ide/AppRun $out/bin/orca-ide \
      --add-flags --no-sandbox

    runHook postInstall
  '';

  # Optional runtime integrations load these dynamically when present.
  autoPatchelfIgnoreMissingDeps = [
    "libcuda.so.1"
    "libvulkan.so.1"
  ];

  meta = {
    description = "Worktree IDE for AI coding agents";
    homepage = "https://www.onorca.dev";
    license = lib.licenses.unfree;
    mainProgram = "orca-ide";
    platforms = [ "x86_64-linux" ];
  };
}
