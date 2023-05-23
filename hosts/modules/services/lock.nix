{ config, lib, pkgs, username, ... }:

with lib;
let cfg = config.my.services.lock;
in {
  options.my.services.lock = {
    enable = mkEnableOption "lock";
    lockService = mkOption {
      type = types.str;
      default = "";
      example = literalExpression "gtklock.service";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.lock = {
      enable = true;
      description = "Lock pre/post suspend trigger";
      serviceConfig = {
        ExecStart =
          "${pkgs.systemd}/bin/systemctl --user -M sinkerine@ start ${cfg.lockService}";
        Type = "oneshot";
      };
      after = [ "systemd-suspend.service" "systemd-hibernate.service" ];
      requiredBy = [ "systemd-suspend.service" "systemd-hibernate.service" ];
    };
  };
}
