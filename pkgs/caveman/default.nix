{
  lib,
  fetchFromGitHub,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation rec {
  pname = "caveman";
  version = "unstable-2026-04-11";

  src = fetchFromGitHub {
    owner = "JuliusBrussee";
    repo = "caveman";
    rev = "600e8efcd6aca4006051ca2a889aa8100a9b3967";
    hash = "sha256-gDPgQx1TIhGrJ2EVvEoDY+4MXdlI79zdcx6pL5nMEG4=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r . "$out/"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Ultra-compressed communication mode for coding agents";
    homepage = "https://github.com/JuliusBrussee/caveman";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
