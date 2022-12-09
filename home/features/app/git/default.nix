{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    userName = "Sinkerine";
    userEmail = "git@15cm.net";

    lfs = { enable = true; };
  };

  home.packages = with pkgs; [ git-secret ];
}
