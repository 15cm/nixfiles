{ pkgs }:

let myPythonPackages = ps: with ps; [ pip docformatter ];
in pkgs.mkShell {
  packages = with pkgs; [
    pdm
    pyright
    black
    isort
    (python3.withPackages myPythonPackages)
  ];
}
