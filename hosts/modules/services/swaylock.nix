{ config, lib, pkgs, username, ... }:

with lib;
let cfg = config.my.services.swaylock;
in {
  options.my.services.swaylock = { enable = mkEnableOption "swaylock"; };

  config = mkIf cfg.enable {
    systemd.services.swaylock = {
      enable = true;
      description = "Swaylock pre/post suspend trigger";
      serviceConfig = {
        ExecStart =
          "${pkgs.systemd}/bin/systemctl --user -M sinkerine@ start swaylock.service";
        Type = "oneshot";
      };
      after = [ "systemd-suspend.service" "systemd-hibernate.service" ];
      requiredBy = [ "systemd-suspend.service" "systemd-hibernate.service" ];
    };
  };
}
