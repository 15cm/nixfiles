{ lib, buildGoPackage, fetchFromGitHub }:

let version = "2.0.0";
in buildGoPackage {
  inherit version;
  pname = "clipper";
  goPackagePath = "github.com/wincent/clipper";

  src = fetchFromGitHub {
    owner = "wincent";
    repo = "clipper";
    rev = version;
    sha256 = "1dqk3621ram5sclzps7lbsl695bwrqpgq8cq000nwpgdwg603lwj";
  };

  meta = with lib; {
    description = "Clipboard access for local and remote tmux sessions ";
    homepage = "https://github.com/wincent/clipper";
    maintainers = [ "i@15cm.net" ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}
