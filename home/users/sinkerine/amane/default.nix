args@{ pkgs, ... }:

{
  home.stateVersion = "23.05";

  imports = [ ../common ];

  my.programs.ai-agents.enable = true;
}
