args@{ pkgs, config, mylib, state, ... }:

let
  inherit (mylib) templateFile templateShellScriptFile writeShellScriptFile;
  templateData = { inherit (state) theme; };
  package = args.withArgs.packageOverride or pkgs.emacs-nox;
in {
  programs.emacs = {
    enable = true;
    inherit package;
  };

  services.emacs = {
    enable = true;
    startWithUserSession = true;
  };

  home.file."local/bin/exec-editor.sh".source =
    writeShellScriptFile "exec-editor.sh" ./exec-editor.sh;
  xdg.configFile."emacs/scripts/load-theme.el".source =
    templateFile "emacs-scripts-load-theme.el" templateData
    ./scripts/load-theme.el.jinja;
}
