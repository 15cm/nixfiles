{ pkgs, fetchzip }:

let
  pname = "sarasa-gothic-nerdfont";
  version = "1.0.12-0";
in pkgs.stdenv.mkDerivation {
  inherit pname version;
  srcs = [
    (fetchzip {
      url =
        "https://github.com/jonz94/Sarasa-Gothic-Nerd-Fonts/releases/download/v${version}/sarasa-mono-sc-nerd-font.zip";
      stripRoot = false;
      hash = "sha256-78MlcMJSu+cImsH7knqUPsdGYiFgja37VX/GJ+P+GxI=";
    })
    (fetchzip {
      url =
        "https://github.com/jonz94/Sarasa-Gothic-Nerd-Fonts/releases/download/v${version}/sarasa-term-sc-nerd-font.zip";
      stripRoot = false;
      hash = "sha256-phlnC1cFEmVH2ltNDeovg1vUSMUA6vML6DJn+Vo4KlQ=";
    })
  ];
  sourceRoot = ".";

  phases = [ "installPhase" ];
  installPhase = ''
    find $srcs -name '*.ttf' | xargs install -m644 --target $out/share/fonts/truetype/sarasa-gothic-nerfont -D
  '';
}
