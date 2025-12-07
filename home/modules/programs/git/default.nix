{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.programs.git;
in {
  options.my.programs.git = { enable = mkEnableOption "Git"; };
  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "Sinkerine";
          email = "git@15cm.net";
        };
        pull.rebase = true;
        init.defaultBranch = "main";
        core.excludesfile = "~/.gitignore_global";
      };
      lfs = { enable = true; };

    };
    home.file.".gitignore_global".source = ./gitignore_global;
  };
}
