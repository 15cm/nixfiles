{
  nixpkgs,
  llm-agents,
  tmux-omni-search,
  fcitx5-vinput,
  ...
}:

with nixpkgs.lib;
let
  llmAgentsFor = system: llm-agents.packages.${system};
  fcitx5VinputFor = system: fcitx5-vinput.packages.${system};
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
  additions =
    final: _prev:
    let
      llmAgentsPkgs = llmAgentsFor final.stdenv.hostPlatform.system;
    in
    (import ../pkgs {
      pkgs = final;
      inherit tmux-omni-search;
    })
    // {
      inherit (llmAgentsPkgs) codex;
      "claude-code" = llmAgentsPkgs.claude-code;
      inherit (fcitx5VinputFor final.stdenv.hostPlatform.system) fcitx5-vinput;
    };
  modifications = final: prev: rec {
    trash-cli = prev.trash-cli.overrideAttrs (old: {
      postInstall = "";
    });
    # pdm is blocked for now by https://github.com/NixOS/nixpkgs/pull/513116.
    feishin = prev.feishin.overrideAttrs overrideElectronDesktopItemForWayland;
    aria2-fast = prev.aria2.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./aria2-fast.patch ];
    });
  };
}
