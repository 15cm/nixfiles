{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.services.swaylock;
in {
  options.my.services.swaylock = { enable = mkEnableOption "swaylock"; };

  config = mkIf cfg.enable {
    programs.swaylock = {
      enable = true;
      settings = {
        image =
          "${config.home.homeDirectory}/Pictures/lockscreens/yurucamp1@2x.png";
      };
    };
    systemd.user.services.swaylock = {
      Unit = { Description = "Swaylock"; };
      Service = {
        ExecStart = "${pkgs.swaylock}/bin/swaylock";
        Type = "simple";
      };
    };
  };
}
