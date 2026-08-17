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
  modifications =
    final: prev:
    let
      orcaPatchedResources = final.fetchurl {
        url = "https://github.com/15cm/orca/releases/download/nix-v1.4.177-notification-focus.1/orca-linux-resources-v1.4.177-notification-focus.1.tar.zst";
        hash = "sha256-2RK9xlfMRVOe4nqbW25huDIJS6UQwQQMmxIKtUn/ldI=";
      };
    in
    rec {
      orca-ide = prev.orca-ide.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.zstd ];
        postInstall = (old.postInstall or "") + ''
          rm -rf $out/opt/orca-ide/resources/app.asar{,.unpacked}
          tar --zstd -xf ${orcaPatchedResources} -C $out/opt/orca-ide/resources
        '';
      });
      trash-cli = prev.trash-cli.overrideAttrs (old: {
        postInstall = "";
      });
      powerline = prev.powerline.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace powerline/commands/daemon.py \
            --replace-fail $'\texclusive_group = parser.add_mutually_exclusive_group()\n' "" \
            --replace-fail $'\texclusive_group.add_argument' $'\tparser.add_argument' \
            --replace-fail $'\treplace_group = exclusive_group.add_argument_group()\n' "" \
            --replace-fail $'\treplace_group.add_argument' $'\tparser.add_argument'
        '';
      });
      # pdm is blocked for now by https://github.com/NixOS/nixpkgs/pull/513116.
      feishin = prev.feishin.overrideAttrs overrideElectronDesktopItemForWayland;
      aria2-fast = prev.aria2.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./aria2-fast.patch ];
      });
    };
}
