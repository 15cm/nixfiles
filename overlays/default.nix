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
      fcitx5-vinput = fcitx5-vinput.packages.${final.stdenv.hostPlatform.system}.default;
    };
  modifications = final: prev: rec {
    trash-cli = prev.trash-cli.overrideAttrs (old: {
      postInstall = "";
    });
    feishin = prev.feishin.overrideAttrs overrideElectronDesktopItemForWayland;
    aria2-fast = prev.aria2.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./aria2-fast.patch ];
    });
  };
}
