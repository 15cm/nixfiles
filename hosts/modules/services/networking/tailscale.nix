{ config, lib, mylib, ... }:

with lib;
let
  cfg = config.my.services.tailscale;
  inherit (mylib) mkDefaultTrueEnableOption;
in {
  options.my.services.tailscale = {
    enable = mkEnableOption "tailscale";
    enableAutoauth = mkDefaultTrueEnableOption "auto auth";
    authUrl = mkOption {
      type = types.str;
      default = "https://headscale.mado.moe";
    };
  };

  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      port = config.my.ports.tailscale.listen;
    };
    systemd.services.tailscale-autoauth = mkIf cfg.enableAutoauth {
      description = "Tailscale autoauth hack";

      after = [ "network-pre.target" "tailscale.service" ];
      wants = [ "network-pre.target" "tailscale.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RestartSec = 10;
        Restart = "on-failure";
      };

      script = ''
        ${config.services.tailscale.package}/bin/tailscale up --accept-dns=false --login-server ${cfg.authUrl} --authkey="file:${config.sops.secrets.tailscaleAuthkey.path}"
      '';
    };
  };
}
