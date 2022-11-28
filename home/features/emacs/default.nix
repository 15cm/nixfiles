args@{ pkgs, config, ... }:

let customConfig = (import ./config.nix { inherit config; });
in {
  # Use the lucid instead of gtk to get a more stable daemon experience.
  programs.emacs = {
    enable = true;
    package = args.withArgs.packageOverride or pkgs.emacs-nox;
  };

  services.myEmacs = {
    enable = true;
    socketActivation = {
      enable = true;
      socketDir = customConfig.socket.dir;
      socketName = customConfig.socket.name;
    };
  };
}
