{ pkgs, lib, python3, }:

python3.pkgs.buildPythonPackage rec {
  pname = "i3-quickterm";
  version = "1.1";

  src = pkgs.python3Packages.fetchPypi {
    inherit pname version;
    sha256 = "sha256-H5qoUaOHA5+rEo9l767Fj56zcIaULPdZ34UaYSOYVyg=";
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
