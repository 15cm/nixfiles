{ config, lib, ... }:

with lib;

let cfg = config.my.services.docker-rootless;
in {
  options.my.services.docker-rootless = {
    enable = mkEnableOption "docker rootless";
    waitForManualZfsLoadKey = mkEnableOption
      "Do not start docker on boot but along with the zfs-load-key-and-mount target";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      virtualisation.docker.rootless = { enable = true; };
    }
    # The user systemd servcie cannot depend on a root systemd service. It has to be brought up manually.
    (mkIf cfg.waitForManualZfsLoadKey {
      systemd.user.services.docker.wantedBy = mkForce [ ];
    })
  ]);
}
