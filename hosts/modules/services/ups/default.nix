{ config, lib, ... }:

with lib;
let cfg = config.my.services.ups;
in {
  options.my.services.ups = { enable = mkEnableOption "ups"; };

  config = mkIf cfg.enable {
    power.ups = {
      enable = true;
      ups.apc = {
        driver = "usbhid-ups";
        port = "auto";
        directives = [ "default.battery.charge.low = 50" ];
      };
    };

    sops.secrets.upsd-users = {
      format = "binary";
      sopsFile = ./upsd.users;
    };
    sops.secrets.upsmon-conf = {
      format = "binary";
      sopsFile = ./upsmon.conf;
    };
    sops.secrets.upsAdminPassword = {
      sopsFile = ./secrets.yaml;
      mode = "0440";
      group = "nut";
    };
    environment.etc."nut/upsd.users".source =
      config.sops.secrets.upsd-users.path;
    environment.etc."nut/upsmon.conf".source =
      config.sops.secrets.upsmon-conf.path;
    environment.etc."nut/upsd.conf".text = "LISTEN 127.0.0.1";

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
