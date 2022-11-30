{ pkgs, fetchFromGitHub }:

let rev = "49fe4753c89615a32f14b2f4c78bbd02ee76be3c";
in pkgs.stdenv.mkDerivation {
  name = "ranger_devicons";
  src = fetchFromGitHub {
    owner = "alexanderjeurissen";
    repo = "ranger_devicons";
    inherit rev;
    sha256 = "sha256-YT7YFiTA2XtIoVzaVjUWMu6j4Nwo4iGzvOtjjWva/80=";
  };

  phases = [ "installPhase" ];
  installPhase = ''
    outdir=$out/share/ranger_devicons
    mkdir -p $outdir
    cp -r $src/* $outdir/
  '';
}
