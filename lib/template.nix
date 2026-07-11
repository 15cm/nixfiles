{ pkgs, lib, ... }:

with lib;
let templatePackage = pkgs.python311.withPackages (ps: [ ps.jinja2 ]);
in rec {
  templateFile = name: data: template:
    pkgs.stdenv.mkDerivation {

      name = "${name}";

      nativeBuildInputs = [ templatePackage ];

      # Pass Json as file to avoid escaping
      passAsFile = [ "jsonData" ];
      jsonData = builtins.toJSON data;

      # Disable phases which are not needed. In particular the unpackPhase will
      # fail, if no src attribute is set
      phases = [ "buildPhase" "installPhase" ];

      buildPhase = ''
        ${templatePackage}/bin/python - "$jsonDataPath" ${template} > rendered_file <<'PY'
        import json
        import sys
        from pathlib import Path

        from jinja2 import Environment, FileSystemLoader

        data_path = Path(sys.argv[1])
        template_path = Path(sys.argv[2])
        env = Environment(
            loader=FileSystemLoader(str(template_path.parent)),
            keep_trailing_newline=True,
        )
        with data_path.open() as data_file:
            data = json.load(data_file)
        print(env.get_template(template_path.name).render(**data), end="")
        PY
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
