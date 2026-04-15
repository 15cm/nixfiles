{
  lib,
  fetchFromGitHub,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation rec {
  pname = "jujutsu-skill";
  version = "unstable-2026-03-06";

  src = fetchFromGitHub {
    owner = "danverbraganza";
    repo = "jujutsu-skill";
    rev = "efcc70090b14e4504d8f8523dd43d6a6605b9a1e";
    hash = "sha256-rDL7M8ukN6vnWF2/G5x7fexsV/1u4M/TVhbrKzM835w=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/skills"
    cp -r jujutsu "$out/skills/jujutsu"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Jujutsu (jj) VCS skill for Claude Code agents";
    homepage = "https://github.com/danverbraganza/jujutsu-skill";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
