{ pkgs, withArgs, ... }:

{
  # Use the lucid instead of gtk to get a more stable daemon experience.
  programs.emacs = {
    enable = true;
    package = pkgs.emacsNativeComp;
  };

  services.myEmacs = {
    enable = true;
    socketActivation = {
      enable = true;
      socketDir = "${withArgs.homeDirectory}/local/run/emacs";
      socketName = "misc";
    };
  };
}
