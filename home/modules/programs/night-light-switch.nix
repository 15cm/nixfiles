{ pkgs, config, lib, nixinfo, ... }:

with lib;
let cfg = config.my.programs.night-light-switch;
in {
  options.my.programs.night-light-switch = {
    enable = mkEnableOption "night-light-switch";
  };

  config = mkIf cfg.enable {
    home.file."local/bin/night-light-control.sh".source =
      pkgs.writeShellScript "night-light-control.sh" ''
        if [ $1 = "off" ]; then
          sed -i "s/.*enableNightLightShader.*/  enableNightLightShader = false;/" ${nixinfo.projectRoot}/home/state/default.nix
        else
          sed -i "s/.*enableNightLightShader.*/  enableNightLightShader = true;/" ${nixinfo.projectRoot}/home/state/default.nix
        fi
        switch-nix-home.sh --option substitute false
      '';
    programs.zsh.shellAliases = {
      nlon = "night-light-control.sh on";
      nloff = "night-light-control.sh off";
    };
  };
}
