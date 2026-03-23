{
  pkgs,
  jailed-agents,
  system,
}:

import ./default.nix {
  inherit pkgs jailed-agents system;
  extraPkgs = with pkgs; [
    tmux
    fzf
  ];
}
