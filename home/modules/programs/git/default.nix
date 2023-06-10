{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.programs.git;
in {
  options.my.programs.git = { enable = mkEnableOption "Git"; };
  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      userName = "Sinkerine";
      userEmail = "git@15cm.net";
      lfs = { enable = true; };

      extraConfig = {
        pull.rebase = true;
        init.defaultBranch = "main";
        core.excludesfile = "~/.gitignore_global";
      };
    };
    home.file.".gitignore_global".source = ./gitignore_global;
  };
}
