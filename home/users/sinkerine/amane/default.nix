args@{ pkgs, ... }:

{
  home.stateVersion = "26.05";

  imports = [ ../common ];

  my.programs.ai-agents.enable = true;
}
