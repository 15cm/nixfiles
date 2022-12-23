{
  xdg.configFile."ssh/interactive.conf".source = ./interactive.conf;
  programs.zsh.shellAliases = {
    ssh = "ssh -F ~/.config/ssh/interactive.conf";
  };
}
