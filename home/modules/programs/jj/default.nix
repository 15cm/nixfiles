{ config, lib, ... }:

with lib;
let
  cfg = config.my.programs.jj;
in {
  options.my.programs.jj = {
    enable = mkEnableOption "Jujutsu";
  };

  config = mkIf cfg.enable {
    programs.jujutsu = {
      enable = true;
      settings = {
        ui.default-command = "log";
        user = {
          name = "Sinkerine";
          email = "git@15cm.net";
        };
      };
    };

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
