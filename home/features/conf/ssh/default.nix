{
  home.file.".ssh/interactive.conf".source = ./interactive.conf;
  programs.zsh.shellAliases = { ssh = "ssh -F ~/.ssh/interactive.conf"; };
}
