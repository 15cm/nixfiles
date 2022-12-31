{ pkgs, fetchzip }:

let
  pname = "sarasa-gothic-nerdfont";
  version = "0.38.0-0";
in pkgs.stdenv.mkDerivation {
  inherit pname version;
  srcs = [
    (fetchzip {
      url =
        "https://github.com/jonz94/Sarasa-Gothic-Nerd-Fonts/releases/download/v${version}/sarasa-mono-sc-nerd-font.zip";
      stripRoot = false;
      hash = "sha256-lA7VeSCpfjoC+ljnuuQJ4zYdm5ofqeNje/cURwvmG2s=";
    })
    (fetchzip {
      url =
        "https://github.com/jonz94/Sarasa-Gothic-Nerd-Fonts/releases/download/v${version}/sarasa-term-sc-nerd-font.zip";
      stripRoot = false;
      hash = "sha256-QZPvX5WucOZGkagO/Aqe/ma78qK4j2FQpr627Wmv4Xs=";
    })
  ];
  sourceRoot = ".";

  phases = [ "installPhase" ];
  installPhase = ''
    find $srcs -name '*.ttf' | xargs install -m644 --target $out/share/fonts/truetype/sarasa-gothic-nerfont -D
  '';
}
