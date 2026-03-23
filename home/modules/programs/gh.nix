{ config, lib, ... }:

with lib;
let
  cfg = config.my.programs.gh;
in {
  options.my.programs.gh = {
    enable = mkEnableOption "GitHub CLI";
  };

  config = mkIf cfg.enable {
    programs.gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
      };
    };
  };
}
