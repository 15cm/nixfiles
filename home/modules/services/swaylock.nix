{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.services.swaylock;
in {
  options.my.services.swaylock = {
    enable = mkEnableOption "swaylock";
    image = mkOption {
      type = with types; nullOr str;
      default = null;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs.swaylock = { enable = true; };
      systemd.user.services.swaylock = {
        Unit = { Description = "Swaylock"; };
        Service = {
          ExecStart = "${pkgs.swaylock}/bin/swaylock";
          Type = "simple";
        };
      };
    }
    (mkIf (cfg.image != null) { programs.swaylock.settings.image = cfg.image; })
  ]);
}
