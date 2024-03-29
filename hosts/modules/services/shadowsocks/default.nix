{ config, lib, ... }:

with lib;
let
  serverCfg = config.my.services.shadowsocks-server;
  clientCfg = config.my.services.shadowsocks-client;
  passwordFile = config.sops.secrets.shadowsocksPassword.path;
in {
  options.my.services = {
    shadowsocks-server = { enable = mkEnableOption "shadowsocks server"; };
    shadowsocks-client = {
      enable = mkEnableOption "shadowsocks client";
      serverAddress = mkOption {
        type = with types; nullOr str;
        default = null;
        description = lib.mdDoc ''
          your hostname or server IP (IPv4/IPv6).
        '';
      };
    };
  };

  config = mkMerge [
    (mkIf (serverCfg.enable || clientCfg.enable) {
      sops.secrets.shadowsocksPassword = { sopsFile = ./secrets.yaml; };
    })
    (mkIf serverCfg.enable {
      services.shadowsocks = {
        enable = true;
        inherit passwordFile;
      };
      networking.firewall = {
        allowedTCPPorts = [ 8388 ];
        allowedUDPPorts = [ 8388 ];
      };
    })
    (mkIf clientCfg.enable {
      services.my.shadowsocks-client = {
        enable = true;
        inherit passwordFile;
        inherit (clientCfg) serverAddress;
      };
    })
  ];
}
