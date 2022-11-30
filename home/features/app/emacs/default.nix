args@{ pkgs, config, mylib, state, ... }:

let
  customConfig = (import ./config.nix { inherit config; });
  inherit (mylib) templateFile;
  templateData = { inherit (state) theme; };
in {
  programs.emacs = {
    enable = true;
    package = args.withArgs.packageOverride or pkgs.emacs-nox;
  };

  services.emacs-misc = {
    enable = true;
    socketActivation = {
      enable = true;
      socketDir = customConfig.socket.dir;
      socketName = customConfig.socket.cli.name;
    };
  };

  xdg.configFile."emacs/scripts/load-theme.el".source =
    templateFile "emacs-scripts-load-theme.el" templateData
    ./scripts/load-theme.el.jinja;
}
