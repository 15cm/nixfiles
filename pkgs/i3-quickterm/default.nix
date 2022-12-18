{ pkgs, lib, python3, fetchFromGitHub }:

python3.pkgs.buildPythonPackage rec {
  pname = "i3-quickterm";
  version = "1.2";

  src = fetchFromGitHub {
    owner = "15cm";
    repo = "i3-quickterm";
    rev = "0114be21787349df3de7644026c5f781ab60dddd";
    hash ="sha256-aTCAEl+eXj20Z7L46x0Et3y37un489mxw+uwtqnuGgY=";
  };

  propagatedBuildInputs = [ pkgs.python3Packages.i3ipc ];
  doCheck = false;

  meta = with lib; {
    description = "A small drop-down terminal for i3 and sway ";
    homepage = "https://github.com/15cm/i3-quickterm";
    license = licenses.mit;
    maintainers = [ "i@15cm.net" ];
  };
}
