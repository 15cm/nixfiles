{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.my.programs.jj;
in {
  options.my.programs.jj = {
    enable = mkEnableOption "Jujutsu";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.jujutsu ];

    xdg.configFile."jj/config.toml".text = ''
      [user]
      name = "Sinkerine"
      email = "git@15cm.net"
    '';

    programs.zsh.shellAliases = {
      j = "jj";
      jb = "jj bookmark";
      jc = "jj commit";
      jd = "jj diff";
      jg = "jj git";
      jl = "jj log";
      jn = "jj new";
      js = "jj status";
    };
  };
}
