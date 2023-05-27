{ pkgs, lib, fetchFromGitHub }:

let
  pname = "khinsider";
  version = "2022-05-08";
in pkgs.stdenv.mkDerivation {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "obskyr";
    repo = "khinsider";
    rev = "b1683fbf2897f04242bd8e67eade940d1b6f2f16";
    hash = "sha256-sSxLicoqS41Ofw5M0K3ERbYZAYe4lgQPKpzWdHNl0vA=";
  };

  propagatedBuildInputs = [
    (pkgs.python3.withPackages
      (pypkgs: with pypkgs; [ requests beautifulsoup4 ]))
  ];
  installPhase = "install -Dm755 $src/khinsider.py $out/bin/khinsider";
  meta = with lib; {
    description =
      "A script for khinsider mass downloads. Get video game soundtracks quickly and easily";
    homepage = "https://github.com/obskyr/khinsider";
    maintainers = [ "i@15cm.net" ];
  };
}
