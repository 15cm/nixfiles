args@{ pkgs, config, lib, mylib, state, ... }:

with lib;

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

  home.activation.gitCloneSpacemacs = hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! [ -d $HOME/.emacs.d ]; then
      ${pkgs.git}/bin/git clone https://github.com/syl20bnr/spacemacs $HOME/.emacs.d
      cd $HOME/.emacs.d
      git switch develop
    fi
  '';
}
