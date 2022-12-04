args@{ pkgs, config, mylib, state, ... }:

let
  customConfig = (import ./config.nix { inherit config; });
  inherit (mylib) templateFile templateShellScriptFile;
  templateData = {
    inherit (state) theme;
    inherit (customConfig) socket;
  };
  package = args.withArgs.packageOverride or pkgs.emacs-nox;
in {
  programs.emacs = {
    enable = true;
    inherit package;
  };

  services.emacs-cli = {
    enable = true;
    socketPath = customConfig.socket.cli.path;
    startWithUserSession = true;
  };

  home.file."local/bin/exec-editor.sh".source =
    templateShellScriptFile "exec-editor.sh" templateData
    ./exec-editor.sh.jinja;
  home.file."local/bin/exec-emacs-gui.sh".source =
    templateShellScriptFile "exec-emacs-gui.sh" templateData
    ./exec-emacs-gui.sh.jinja;
  xdg.configFile."emacs/scripts/load-theme.el".source =
    templateFile "emacs-scripts-load-theme.el" templateData
    ./scripts/load-theme.el.jinja;
}
