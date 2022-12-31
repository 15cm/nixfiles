{ config, pkgs, lib, mylib, state, ... }:

with lib;
let
  cfg = config.my.programs.emacs;
  inherit (mylib) templateFile writeShellScriptFile;
  templateData = { inherit (state) theme; };
in {
  options.my.programs.emacs = {
    enable = mkEnableOption "emacs";
    package = mkOption {
      type = types.package;
      default = pkgs.myEmacs-nox;
    };
    enableSSHSpacemacsConfigRepo = mkEnableOption "ssh url in ~/.spacemacs.d";
    spacemacsConfigRepoUrl = mkOption {
      type = types.str;
      readOnly = true;
      internal = true;
      default = if cfg.enableSSHSpacemacsConfigRepo then
        "git@github.com:15cm/spacemacs-config.git"
      else
        "https://github.com/15cm/spacemacs-config.git";
    };
    startAfterXSession = mkEnableOption "start after xsession";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs.emacs = {
        enable = true;
        inherit (cfg) package;
      };
      services.emacs = {
        enable = true;
        startWithUserSession = !cfg.startAfterXSession;
      };

      home.file."local/bin/exec-editor.sh".source =
        writeShellScriptFile "exec-editor.sh" ./exec-editor.sh;
      xdg.configFile."emacs/scripts/load-theme.el".source =
        templateFile "emacs-scripts-load-theme.el" templateData
        ./scripts/load-theme.el.jinja;

      home.activation.gitCloneSpacemacs =
        hm.dag.entryAfter [ "writeBoundary" ] ''
          if ! [ -d $HOME/.emacs.d ]; then
            ${pkgs.git}/bin/git clone https://github.com/syl20bnr/spacemacs $HOME/.emacs.d
            cd $HOME/.emacs.d
            ${pkgs.git}/bin/git switch develop
          fi
        '';

      home.activation.gitCloneSpacemacsConfig =
        hm.dag.entryAfter [ "writeBoundary" ] ''
          if ! [ -d $HOME/.spacemacs.d ]; then
            ${pkgs.git}/bin/git clone ${cfg.spacemacsConfigRepoUrl} $HOME/.spacemacs.d
          fi
        '';
    }
    (mkIf cfg.startAfterXSession {
      systemd.user.services.emacs = {
        Unit = {
          After = [ "graphical-session-pre.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
    })
  ]);
}
