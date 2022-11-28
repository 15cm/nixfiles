{ pkgs, withArgs, ... }:

let config = (import ./config.nix withArgs.homeDirectory);
in {
  # Use the lucid instead of gtk to get a more stable daemon experience.
  programs.emacs = {
    enable = true;
    package = pkgs.emacsNativeComp;
  };

  services.myEmacs = {
    enable = true;
    socketActivation = {
      enable = true;
      socketDir = config.socket.dir;
      socketName = config.socket.name;
    };
  };
}
