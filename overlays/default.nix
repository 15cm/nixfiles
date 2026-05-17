{
  nixpkgs,
  llm-agents,
  tmux-omni-search,
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
    };
  modifications = final: prev: rec {
    trash-cli = prev.trash-cli.overrideAttrs (old: {
      postInstall = "";
    });
    pdm = prev.pdm.overrideAttrs (old: rec {
      version = "2.26.8";
      src = final.fetchFromGitHub {
        owner = "pdm-project";
        repo = "pdm";
        tag = version;
        hash = "sha256-9bUyiRsvCI4YUK3LVguy0yHSOPHL9gLwLKK9R745Bd0=";
      };
      disabledTests = (old.disabledTests or [ ]) ++ [
        # Broken by pypa/installer#325 with installer 1.x.
        "test_can_install_wheel_with_cache_in_multiple_projects[PythonEnvironment-symlink]"
        "test_can_install_wheel_with_cache_in_multiple_projects[PythonLocalEnvironment-symlink]"
        "test_install_wheel_with_cache[PythonEnvironment-symlink]"
        "test_install_wheel_with_cache[PythonLocalEnvironment-symlink]"
        "test_install_wheel_with_data_scripts[PythonEnvironment-True]"
        "test_install_wheel_with_data_scripts[PythonLocalEnvironment-True]"
        "test_uninstall_with_console_scripts[PythonEnvironment-True]"
        "test_uninstall_with_console_scripts[PythonLocalEnvironment-True]"
        "test_url_requirement_is_not_cached[PythonEnvironment]"
        "test_url_requirement_is_not_cached[PythonLocalEnvironment]"
      ];
    });
    feishin = prev.feishin.overrideAttrs overrideElectronDesktopItemForWayland;
    aria2-fast = prev.aria2.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./aria2-fast.patch ];
    });
  };
}
