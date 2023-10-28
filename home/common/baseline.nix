{ config, pkgs, state, nixinfo, hostname, ... }:

let parallel = pkgs.parallel-full.override (old: { willCite = true; });
in {
  programs.home-manager.enable = true;

  imports = [ ../features/conf/misc-dotfiles ];

  home.packages = (with pkgs; [
    nixfmt
    eza
    fd
    htop
    lsof
    ripgrep
    silver-searcher
    bind
    hunspell
    hunspellDicts.en_US-large
    parallel
    tree
  ]);

  my.services.nix-home-manager-gc.enable = true;
  my.programs.git.enable = true;
  my.programs.zsh.enable = true;
  my.programs.fontconfig.enable = true;
  my.programs.emacs.enable = true;
  my.programs.vim.enable = true;
  my.programs.tmux.enable = true;
  my.programs.fzf.enable = true;
  my.programs.set-theme.enable = true;
  my.programs.yazi.enable = true;
  my.programs.navi.enable = true;
  my.programs.hmSwitch.enable = true;
  my.programs.powerline.enable = true;
  programs.bottom = {
    enable = true;
    settings = {
      flags = {
        color = (if state.theme == "light" then "gruvbox-light" else "gruvbox");
      };
    };
  };
  programs.zoxide = { enable = true; };
  programs.tealdeer = {
    enable = true;
    settings = { updates = { auto_update = true; }; };
  };
}
