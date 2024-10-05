{ nixpkgs, ... }:

with nixpkgs.lib;
let
  overrideElectronDesktopItemForWayland = (old: rec {
    desktopItems = (map (desktopItem:
      desktopItem.override (d: {
        exec =
          "${d.exec} --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime";
      })) old.desktopItems);
  });
in {
  # Adds my custom packages
  additions = final: _prev: import ../pkgs { pkgs = final; };
  modifications = final: prev: rec {
    trash-cli = prev.trash-cli.overrideAttrs (old: { postInstall = ""; });
    feishin = prev.feishin.overrideAttrs overrideElectronDesktopItemForWayland;
    aria2-fast = prev.aria2.overrideAttrs
      (old: { patches = (old.patches or [ ]) ++ [ ./aria2-fast.patch ]; });
  };
}
