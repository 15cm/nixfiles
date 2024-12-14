{ config, lib, ... }:

with lib;
let cfg = config.my.services.ups;
in {
  options.my.services.ups = { enable = mkEnableOption "ups"; };

  config = mkIf cfg.enable {
    power.ups = {
      enable = true;
      ups.nas = {
        driver = "usbhid-ups";
        port = "auto";
        directives = [ "default.battery.charge.low = 50" ];
      };
      users.admin = {
        passwordFile = config.sops.secrets.upsAdminPassword.path;
        instcmds = [ "all" ];
        actions = [ "set" "fsd" ];
      };
      upsmon = {
        monitor."nas@localhost" = {
          user = "admin";
          passwordFile = config.sops.secrets.upsAdminPassword.path;
        };
      };
    };

    sops.secrets.upsAdminPassword = {
      sopsFile = ./secrets.yaml;
      mode = "0440";
      group = "nut";
    };

    users.users.nut = {
      uid = 84;
      isSystemUser = true;
      home = "/var/lib/nut";
      createHome = true;
      group = "nut";
      description = "UPnP A/V Media Server user";
    };
    users.groups."nut" = { gid = config.my.ids.uids.nut; };
  };
}
