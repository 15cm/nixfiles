{ config, lib, ... }:

with lib;
let cfg = config.my.programs.navi;
in {
  options.my.programs.navi = { enable = mkEnableOption "navi"; };

  config = mkIf cfg.enable {
    programs.navi = {
      enable = true;
      enableZshIntegration = true;
    };
    home.file.".config/navi/config.yaml".text = ''
      cheats:
        paths:
          - ${config.home.homeDirectory}/.navi
    '';
  };
}
