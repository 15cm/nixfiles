args@{ pkgs, config, ... }:

let customConfig = (import ./config.nix { inherit config; });
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
}
