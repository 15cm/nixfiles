{ nixpkgs, ... }:

with nixpkgs.lib;
let
  overrideElectronDesktopItemForWayland = (
    old: rec {
      desktopItems = (
        map (
          desktopItem:
          desktopItem.override (d: {
            exec = "${d.exec} --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime";
          })
        ) old.desktopItems
      );
    }
  );
in
{
  # Adds my custom packages
  additions = final: _prev: import ../pkgs { pkgs = final; };
  modifications = final: prev: rec {
    trash-cli = prev.trash-cli.overrideAttrs (old: {
      postInstall = "";
    });
    feishin = prev.feishin.overrideAttrs overrideElectronDesktopItemForWayland;
    aria2-fast = prev.aria2.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./aria2-fast.patch ];
    });
    codex-base = prev.codex.overrideAttrs (_old: {
      patches = (_old.patches or [ ]) ++ [ ./codex-remove-dumb-term.patch ];
    });
    codex = final.symlinkJoin {
      name = "codex-${final.codex-base.version}";
      paths = [ final.codex-base ];
      nativeBuildInputs = [ final.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/codex \
          --prefix PATH : ${final.lib.makeBinPath [ final.ripgrep ]} \
          --run '
            project_path=$PWD
            project_path=''${project_path//\\/\\\\}
            project_path=''${project_path//\"/\\\"}
            set -- -c "projects={\"$project_path\"={trust_level=\"trusted\"}}" "$@"
          ' \
          --set TERM dumb
      '';
      meta = final.codex-base.meta;
    };
  };
}
