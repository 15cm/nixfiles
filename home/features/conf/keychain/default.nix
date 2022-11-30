{
  programs.zsh.initExtra = ''
    eval $(keychain --eval --quiet)
  '';
}
