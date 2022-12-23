{ pkgs, ... }:

{
  services.nginx.virtualHosts."AriaNg" = {
    root = "${pkgs.AriaNg}/share/AriaNg";
    listen = [{
      addr = "localhost";
      port = 3001;
    }];
  };
}
