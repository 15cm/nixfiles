{ pkgs, fetchzip }:

let
  pname = "iosevka-nerdfont";
  version = "3.0.1";
in pkgs.stdenv.mkDerivation {
  inherit pname version;
  srcs = [
    (fetchzip {
      url =
        "https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/Iosevka.zip";
      stripRoot = false;
      hash = "sha256-yAWtn3bl9ww4/FyINszasyKXiRqjMgUsXif4/25JoVg=";
    })
  ];
  sourceRoot = ".";

  phases = [ "installPhase" ];
  installPhase = ''
    find $srcs -name '*.ttf' | xargs install -m644 --target $out/share/fonts/truetype/iosevka-nerfont -D
  '';
}
