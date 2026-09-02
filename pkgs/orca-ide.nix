{
  autoPatchelfHook,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  copyDesktopItems,
  cups,
  dbus,
  electron_43,
  expat,
  fetchFromGitHub,
  fetchPnpmDeps,
  fontconfig,
  freetype,
  gnumake,
  gdk-pixbuf,
  glib,
  gtk3,
  lib,
  libdrm,
  libgbm,
  libnotify,
  libsecret,
  libx11,
  libxcb,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxinerama,
  libxkbcommon,
  libxrandr,
  libxscrnsaver,
  libxshmfence,
  libxtst,
  makeDesktopItem,
  makeWrapper,
  node-gyp,
  nodejs_24,
  nspr,
  nss,
  pango,
  pipewire,
  pnpmConfigHook,
  pnpm_10,
  pkg-config,
  python3,
  stdenv,
  systemd,
  wayland,
}:

let
  electron = electron_43;
  pnpm = pnpm_10;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "orca-ide";
  version = "1.4.178-rc.2-d0fe1ec";

  # Pinned from the custom branch: https://github.com/15cm/orca/tree/custom
  src = fetchFromGitHub {
    owner = "15cm";
    repo = "orca";
    rev = "d0fe1ec4a8e7c6320683c795979c08acec53566d";
    hash = "sha256-ojD9ynyGALtIO/MDD5UmxuNHe1RkgBY/mKVl67R1Xak=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    inherit pnpm;
    fetcherVersion = 4;
    hash = "sha256-kBKZZrxwCEEUwt0NDQYBj5qtcXGU1WePoDuh5/ULRTU=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
    gnumake
    makeWrapper
    node-gyp
    nodejs_24
    pkg-config
    pnpm
    pnpmConfigHook
    python3
    stdenv.cc
  ];

  buildInputs = [
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    electron
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libgbm
    libnotify
    libsecret
    libx11
    libxcb
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxinerama
    libxkbcommon
    libxrandr
    libxscrnsaver
    libxshmfence
    libxtst
    nspr
    nss
    pango
    pipewire
    systemd
    wayland
  ];

  strictDeps = true;

  env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

  # Nix supplies Electron and its native runtime. Orca's release hook would
  # otherwise try to download Electron and rebuild native modules online.
  postPatch = ''
    # The Nix Electron runtime is supplied by nixpkgs; avoid the upstream
    # release hook's online Electron download and native rebuild.
    substituteInPlace config/electron-builder.config.cjs \
      --replace-fail \
        "beforeBuild: electronBuilderNativeRebuild," \
        "beforeBuild: null,"
    # Static musl helper binaries have no dynamic symbol table. Keep the
    # upstream relocated-symbol check for binaries with DT_NEEDED entries.
    substituteInPlace config/scripts/verify-linux-glibc-floor.cjs \
      --replace-fail \
        "const providerViolations = Object.values(RELOCATED_SYMBOL_PROVIDERS).some(" \
        "const providerViolations = neededLibraries.size > 0 && Object.values(RELOCATED_SYMBOL_PROVIDERS).some("
    # Nix's current Electron and compiler target the host nixpkgs glibc, not
    # the upstream Ubuntu 20.04 compatibility floor.
    substituteInPlace config/electron-builder.config.cjs \
      --replace-fail \
        "verifyLinuxGlibcFloor(context.appOutDir)" \
        "void context.appOutDir"
    # Electron's ELECTRON_RUN_AS_NODE mode sets PR_SET_NO_NEW_PRIVS on Linux.
    # Orca's detached terminal daemon must remain able to launch explicitly
    # authorized host helpers such as the gui-sandbox root-owned CLI.
    substituteInPlace src/main/daemon/daemon-init.ts \
      --replace-fail \
        "          ...(relocatedHost ? { execPath: relocatedHost.execPath } : {})," \
        "          ...(process.platform === 'linux' ? { execPath: '${nodejs_24}/bin/node' } : relocatedHost ? { execPath: relocatedHost.execPath } : {}),"
  '';

  buildPhase = ''
    runHook preBuild

    export npm_config_nodedir=${nodejs_24}
    pnpm rebuild node-pty

    pnpm run build:desktop

    cp -r ${electron.dist} electron-dist
    chmod -R u+w electron-dist

    pnpm exec electron-builder \
      --dir \
      --config config/electron-builder.config.cjs \
      -c.electronDist=electron-dist \
      -c.electronVersion=${electron.version} \
      -c.npmRebuild=false

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/orca-ide
    cp -r dist/*-unpacked/resources $out/opt/orca-ide/
    install -Dm444 resources/build/icon.png \
      $out/share/icons/hicolor/1024x1024/apps/orca-ide.png

    runHook postInstall
  '';

  postFixup = ''
    makeWrapper ${lib.getExe electron} $out/bin/orca-ide \
      --inherit-argv0 \
      --set ELECTRON_FORCE_IS_PACKAGED 1 \
      --add-flags --no-sandbox \
      --add-flags $out/opt/orca-ide/resources/app.asar
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "orca-ide";
      desktopName = "Orca";
      comment = "Worktree IDE for AI coding agents";
      exec = "orca-ide %U";
      icon = "orca-ide";
      startupWMClass = "orca";
      categories = [ "Development" ];
    })
  ];

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
})
