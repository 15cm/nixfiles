{ pkgs, config, lib, ... }:

with lib;
let cfg = config.my.programs.flameshot;
in {
  options.my.programs.flameshot = { enable = mkEnableOption "Flameshot"; };
  config = mkIf cfg.enable {
    services.flameshot = {
      enable = true;
      package = pkgs.symlinkJoin {
        name = "flameshot";
        paths = [ pkgs.flameshot ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/flameshot \
            --set XDG_CURRENT_DESKTOP sway
        '';
      };
      settings = {
        General = {
          disabledTrayIcon = false;
          showStartupLaunchMessage = false;
          saveAsFileExtension = "png";
          savePathFixed = true;
          savePath = "${config.home.homeDirectory}/Screenshots";
        };
      };
    };
  };
}
