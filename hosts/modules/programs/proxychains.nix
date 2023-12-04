{ config, lib, pkgs, ... }:

with lib;
let cfg = config.my.programs.proxychains;
in {
  options.my.programs.proxychains = { enable = mkEnableOption "proxychains"; };

  config = mkIf cfg.enable {
    programs.proxychains = {
      enable = true;
      package = pkgs.proxychains-ng;
      proxies.default = {
        enable = true;
        type = "socks5";
        host = "127.0.0.1";
        port = config.services.my.shadowsocks-client.localPort;
      };
    };
  };
}
