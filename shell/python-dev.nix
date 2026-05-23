{ pkgs }:

let
  myPythonPackages =
    ps: with ps; [
      pip
      docformatter
    ];
in
pkgs.mkShell {
  packages = with pkgs; [
    # pdm is blocked for now by https://github.com/NixOS/nixpkgs/pull/513116.
    pyright
    black
    isort
    (python3.withPackages myPythonPackages)
  ];
}
