args@{ pkgs, ... }:

{
  home.stateVersion = "23.05";

  imports = [ ../common ];

  my.programs.emacs = { enableSSHSpacemacsConfigRepo = true; };
}
