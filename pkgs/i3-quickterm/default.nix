{ pkgs, lib, python3, fetchFromGitHub }:

let
  pname = "i3-quickterm";
  version = "1.1";
in python3.pkgs.buildPythonPackage {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "lbonn";
    repo = "i3-quickterm";
    rev = "v${version}";
    hash = "sha256-kHj3hiOm4HvrQ9Xr80wgtX1Tq830XIiFbeet7lLSNCI=";
  };

  propagatedBuildInputs = [ pkgs.python3Packages.i3ipc ];
  doCheck = false;

  meta = with lib; {
    description = "A small drop-down terminal for i3 and sway ";
    homepage = "https://github.com/lbonn/i3-quickterm";
    license = licenses.mit;
    maintainers = [ "i@15cm.net" ];
  };
}
