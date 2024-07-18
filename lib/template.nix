{ pkgs, lib, ... }:

with lib;
let templatePackage = pkgs.python311Packages.j2cli;
in rec {
  templateFile = name: data: template:
    pkgs.stdenv.mkDerivation {

      name = "${name}";

      nativeBuildInpts = [ templatePackage ];

      # Pass Json as file to avoid escaping
      passAsFile = [ "jsonData" ];
      jsonData = builtins.toJSON data;

      # Disable phases which are not needed. In particular the unpackPhase will
      # fail, if no src attribute is set
      phases = [ "buildPhase" "installPhase" ];

      buildPhase = ''
        ${templatePackage}/bin/j2 -f json ${template} $jsonDataPath > rendered_file
      '';

      installPhase = ''
        cp rendered_file $out
      '';
    };
  templateShellScriptFile = name: data: template:
    pipe template [
      (templateFile name data)
      builtins.readFile
      (pkgs.writeShellScript name)
    ];
  writeShellScriptFile = name: file:
    pipe file [ builtins.readFile (pkgs.writeShellScript name) ];

  toJSONFile = name: expr: pipe expr [ builtins.toJSON (builtins.toFile name) ];
}
